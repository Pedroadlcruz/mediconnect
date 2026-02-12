import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:injectable/injectable.dart';
import 'package:mediconnect/features/consultation/data/data_sources/signaling_service.dart';

part 'call_event.dart';
part 'call_state.dart';

@injectable
class CallBloc extends Bloc<CallEvent, CallState> {
  final SignalingService _signalingService;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;

  String _currentRoomId = '';
  bool _isAudioOnly = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  Timer? _reconnectTimer;

  CallBloc(this._signalingService) : super(CallInitial()) {
    on<CallStarted>(_onCallStarted);
    on<CallHungUp>(_onCallHungUp);
    on<ToggleCamera>(_onToggleCamera);
    on<ToggleMicrophone>(_onToggleMicrophone);
    on<SwitchCamera>(_onSwitchCamera);
    on<_ConnectionStateChanged>(_onConnectionStateChanged);
    on<CallReconnectRequested>(_onReconnectRequested);
    on<CallFallbackToAudio>(_onFallbackToAudio);
  }

  Future<void> _onCallStarted(
    CallStarted event,
    Emitter<CallState> emit,
  ) async {
    emit(CallLoading());
    try {
      await _initializeCall(event.roomId, emit);
    } catch (e) {
      emit(CallFailure(e.toString(), canRetry: true));
    }
  }

  Future<void> _initializeCall(String? roomId, Emitter<CallState> emit) async {
    print('DEBUG: [CallBloc] Starting _initializeCall');
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    // Get user media
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': _isAudioOnly
          ? false
          : {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            },
    };

    print('DEBUG: [CallBloc] Getting User Media...');
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    print('DEBUG: [CallBloc] User Media obtained');
    _localRenderer.srcObject = _localStream;

    // Create Peer Connection
    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    };

    print('DEBUG: [CallBloc] Creating Peer Connection...');
    _peerConnection = await createPeerConnection(configuration);
    print('DEBUG: [CallBloc] Peer Connection created');

    // Monitor connection states
    _peerConnection!.onIceConnectionState = (RTCIceConnectionState iceState) {
      print('DEBUG: [CallBloc] ICE Connection State: ${iceState.toString()}');
      if (!isClosed) {
        add(_ConnectionStateChanged(iceState));
      }
    };

    _peerConnection!.onSignalingState = (RTCSignalingState signalingState) {
      print('DEBUG: [CallBloc] Signaling State: ${signalingState.toString()}');
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      print('DEBUG: [CallBloc] Peer Connection State: ${state.toString()}');
    };

    // Add local stream to connection
    print('DEBUG: [CallBloc] Adding tracks...');
    for (final track in _localStream!.getTracks()) {
      if (track.kind != null) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }
    print('DEBUG: [CallBloc] Tracks added');

    // Handle remote stream
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      print('DEBUG: [CallBloc] Remote track received: ${event.track.kind}');
      if (event.streams.isNotEmpty) {
        print('DEBUG: [CallBloc] Attaching stream from track event');
        _remoteRenderer.srcObject = event.streams[0];
      } else {
        print(
          'DEBUG: [CallBloc] event.streams is empty, creating new MediaStream',
        );
        // Fallback: create a stream if none provided
        if (_remoteRenderer.srcObject == null) {
          _createRemoteStreamFromTrack(event.track);
        } else {
          final existingStream = _remoteRenderer.srcObject as MediaStream;
          existingStream.addTrack(event.track);
        }
      }
    };

    _peerConnection!.onAddStream = (MediaStream stream) {
      print('DEBUG: [CallBloc] Remote stream added via onAddStream');
      _remoteRenderer.srcObject = stream;
    };

    _currentRoomId = roomId ?? '';
    if (_currentRoomId.isEmpty) {
      print('DEBUG: [CallBloc] Creating Room...');
      _currentRoomId = await _signalingService.createRoom(_peerConnection!);
      print('DEBUG: [CallBloc] Room created with ID: $_currentRoomId');
    } else {
      print('DEBUG: [CallBloc] Joining Room: $_currentRoomId');
      await _signalingService.joinRoom(_currentRoomId, _peerConnection!);
      print('DEBUG: [CallBloc] Room joined');
    }

    emit(
      CallReady(
        roomId: _currentRoomId,
        localRenderer: _localRenderer,
        remoteRenderer: _remoteRenderer,
        isAudioOnly: _isAudioOnly,
        reconnectAttempts: _reconnectAttempts,
      ),
    );
  }

  void _onConnectionStateChanged(
    _ConnectionStateChanged event,
    Emitter<CallState> emit,
  ) {
    if (state is! CallReady && state is! CallReconnecting) return;

    switch (event.iceState) {
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
      case RTCIceConnectionState.RTCIceConnectionStateCompleted:
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();
        if (state is CallReconnecting ||
            (state is CallReady &&
                (state as CallReady).connectionQuality !=
                    ConnectionQuality.excellent)) {
          emit(
            CallReady(
              roomId: _currentRoomId,
              localRenderer: _localRenderer,
              remoteRenderer: _remoteRenderer,
              connectionQuality: ConnectionQuality.excellent,
              isAudioOnly: _isAudioOnly,
              reconnectAttempts: 0,
            ),
          );
        }
        break;

      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        // Temporary disconnection — mark as poor quality, wait briefly
        if (state is CallReady) {
          emit(
            (state as CallReady).copyWith(
              connectionQuality: ConnectionQuality.poor,
            ),
          );
        }
        // Start auto-reconnect timer
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(const Duration(seconds: 5), () {
          if (!isClosed &&
              state is CallReady &&
              (state as CallReady).connectionQuality ==
                  ConnectionQuality.poor) {
            add(CallReconnectRequested());
          }
        });
        break;

      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        // Connection failed — attempt reconnection
        _reconnectTimer?.cancel();
        if (!isClosed) {
          add(CallReconnectRequested());
        }
        break;

      case RTCIceConnectionState.RTCIceConnectionStateClosed:
        // Connection fully closed
        if (state is! CallEnded) {
          emit(CallEnded());
        }
        break;

      default:
        break;
    }
  }

  Future<void> _onReconnectRequested(
    CallReconnectRequested event,
    Emitter<CallState> emit,
  ) async {
    _reconnectAttempts++;

    if (_reconnectAttempts > _maxReconnectAttempts) {
      // Max attempts exceeded — suggest fallback to audio
      if (!_isAudioOnly) {
        emit(
          const CallFailure(
            'No se pudo restablecer la conexión de video después de $_maxReconnectAttempts intentos.\n¿Desea continuar solo con audio?',
            canRetry: true,
          ),
        );
      } else {
        emit(
          const CallFailure(
            'No se pudo restablecer la llamada. El otro participante puede haber desconectado.',
            canRetry: false,
          ),
        );
      }
      return;
    }

    emit(
      CallReconnecting(
        roomId: _currentRoomId,
        attempt: _reconnectAttempts,
        maxAttempts: _maxReconnectAttempts,
      ),
    );

    try {
      // Cleanup old peer connection
      await _peerConnection?.close();
      _peerConnection = null;

      // Small delay before reconnecting
      await Future.delayed(Duration(seconds: _reconnectAttempts));

      // Create new peer connection
      final configuration = <String, dynamic>{
        'iceServers': [
          {'urls': 'stun:stun1.l.google.com:19302'},
          {'urls': 'stun:stun2.l.google.com:19302'},
        ],
        'sdpSemantics': 'unified-plan',
      };

      _peerConnection = await createPeerConnection(configuration);

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState iceState) {
        if (!isClosed) {
          add(_ConnectionStateChanged(iceState));
        }
      };

      // Re-add existing tracks
      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) {
          if (track.kind != null) {
            await _peerConnection!.addTrack(track, _localStream!);
          }
        }
      }

      // Handle remote stream with improved logic
      _peerConnection!.onTrack = (RTCTrackEvent trackEvent) {
        print(
          'DEBUG: [CallBloc] Remote track received (reconnect): ${trackEvent.track.kind}',
        );
        if (trackEvent.streams.isNotEmpty) {
          _remoteRenderer.srcObject = trackEvent.streams[0];
        } else {
          if (_remoteRenderer.srcObject == null) {
            _createRemoteStreamFromTrack(trackEvent.track);
          } else {
            final existingStream = _remoteRenderer.srcObject as MediaStream;
            existingStream.addTrack(trackEvent.track);
          }
        }
      };

      _peerConnection!.onAddStream = (MediaStream stream) {
        print('DEBUG: [CallBloc] Remote stream added (reconnect)');
        _remoteRenderer.srcObject = stream;
      };

      // Re-join the room with new peer connection
      await _signalingService.joinRoom(_currentRoomId, _peerConnection!);

      emit(
        CallReady(
          roomId: _currentRoomId,
          localRenderer: _localRenderer,
          remoteRenderer: _remoteRenderer,
          connectionQuality: ConnectionQuality.reconnecting,
          isAudioOnly: _isAudioOnly,
          reconnectAttempts: _reconnectAttempts,
        ),
      );
    } catch (e) {
      // Retry on next attempt
      if (!isClosed && _reconnectAttempts < _maxReconnectAttempts) {
        add(CallReconnectRequested());
      } else {
        emit(
          CallFailure(
            'Error de reconexión: ${e.toString()}',
            canRetry: !_isAudioOnly,
          ),
        );
      }
    }
  }

  Future<void> _onFallbackToAudio(
    CallFallbackToAudio event,
    Emitter<CallState> emit,
  ) async {
    emit(CallLoading());

    try {
      // Stop video tracks
      final videoTracks = _localStream?.getVideoTracks() ?? [];
      for (final track in videoTracks) {
        track.stop();
        try {
          await _localStream!.removeTrack(track);
        } catch (_) {
          // Track may already be removed
        }
      }

      // Close old peer connection
      await _peerConnection?.close();
      _peerConnection = null;

      _isAudioOnly = true;
      _reconnectAttempts = 0;

      // Get audio-only stream
      final audioConstraints = <String, dynamic>{'audio': true, 'video': false};

      _localStream = await navigator.mediaDevices.getUserMedia(
        audioConstraints,
      );
      _localRenderer.srcObject = _localStream;

      // Create new peer connection
      final configuration = <String, dynamic>{
        'iceServers': [
          {'urls': 'stun:stun1.l.google.com:19302'},
          {'urls': 'stun:stun2.l.google.com:19302'},
        ],
        'sdpSemantics': 'unified-plan',
      };

      _peerConnection = await createPeerConnection(configuration);

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState iceState) {
        if (!isClosed) {
          add(_ConnectionStateChanged(iceState));
        }
      };

      for (final track in _localStream!.getTracks()) {
        if (track.kind != null) {
          await _peerConnection!.addTrack(track, _localStream!);
        }
      }

      _peerConnection!.onTrack = (RTCTrackEvent trackEvent) {
        print(
          'DEBUG: [CallBloc] Remote track received (fallback): ${trackEvent.track.kind}',
        );
        if (trackEvent.streams.isNotEmpty) {
          _remoteRenderer.srcObject = trackEvent.streams[0];
        } else {
          if (_remoteRenderer.srcObject == null) {
            _createRemoteStreamFromTrack(trackEvent.track);
          } else {
            final existingStream = _remoteRenderer.srcObject as MediaStream;
            existingStream.addTrack(trackEvent.track);
          }
        }
      };

      _peerConnection!.onAddStream = (MediaStream stream) {
        print('DEBUG: [CallBloc] Remote stream added (fallback)');
        _remoteRenderer.srcObject = stream;
      };

      // Re-join room with audio only
      await _signalingService.joinRoom(_currentRoomId, _peerConnection!);

      emit(
        CallReady(
          roomId: _currentRoomId,
          localRenderer: _localRenderer,
          remoteRenderer: _remoteRenderer,
          connectionQuality: ConnectionQuality.good,
          isAudioOnly: true,
          reconnectAttempts: 0,
        ),
      );
    } catch (e) {
      emit(CallFailure('Error al cambiar a modo de voz: ${e.toString()}'));
    }
  }

  Future<void> _onCallHungUp(CallHungUp event, Emitter<CallState> emit) async {
    _reconnectTimer?.cancel();

    if (state is CallReady) {
      final roomId = (state as CallReady).roomId;
      await _signalingService.hangUp(roomId);
    } else if (_currentRoomId.isNotEmpty) {
      await _signalingService.hangUp(_currentRoomId);
    }

    _localStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();
    await _localRenderer.dispose();
    await _remoteRenderer.dispose();
    await _peerConnection?.close();

    emit(CallEnded());
  }

  void _onToggleCamera(ToggleCamera event, Emitter<CallState> emit) {
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      final bool enabled = _localStream!.getVideoTracks()[0].enabled;
      _localStream!.getVideoTracks()[0].enabled = !enabled;
    }
  }

  void _onToggleMicrophone(ToggleMicrophone event, Emitter<CallState> emit) {
    if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
      final bool enabled = _localStream!.getAudioTracks()[0].enabled;
      _localStream!.getAudioTracks()[0].enabled = !enabled;
    }
  }

  Future<void> _onSwitchCamera(
    SwitchCamera event,
    Emitter<CallState> emit,
  ) async {
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      await Helper.switchCamera(_localStream!.getVideoTracks()[0]);
    }
  }

  Future<void> _createRemoteStreamFromTrack(MediaStreamTrack track) async {
    try {
      final stream = await createLocalMediaStream('remote_stream');
      await stream.addTrack(track);
      _remoteRenderer.srcObject = stream;
      print(
        'DEBUG: [CallBloc] Created remote stream from track: ${track.kind}',
      );
    } catch (e) {
      print('DEBUG: [CallBloc] Error creating remote stream: $e');
    }
  }

  @override
  Future<void> close() {
    _reconnectTimer?.cancel();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    return super.close();
  }
}
