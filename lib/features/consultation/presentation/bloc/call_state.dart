part of 'call_bloc.dart';

enum ConnectionQuality { excellent, good, poor, disconnected, reconnecting }

abstract class CallState extends Equatable {
  const CallState();

  @override
  List<Object?> get props => [];
}

class CallInitial extends CallState {}

class CallLoading extends CallState {}

class CallReady extends CallState {
  final String roomId;
  final RTCVideoRenderer localRenderer;
  final RTCVideoRenderer remoteRenderer;
  final ConnectionQuality connectionQuality;
  final bool isAudioOnly;
  final bool isMuted;
  final bool isCameraOff;
  final int reconnectAttempts;

  const CallReady({
    required this.roomId,
    required this.localRenderer,
    required this.remoteRenderer,
    this.connectionQuality = ConnectionQuality.good,
    this.isAudioOnly = false,
    this.isMuted = false,
    this.isCameraOff = false,
    this.reconnectAttempts = 0,
  });

  CallReady copyWith({
    ConnectionQuality? connectionQuality,
    bool? isAudioOnly,
    bool? isMuted,
    bool? isCameraOff,
    int? reconnectAttempts,
  }) {
    return CallReady(
      roomId: roomId,
      localRenderer: localRenderer,
      remoteRenderer: remoteRenderer,
      connectionQuality: connectionQuality ?? this.connectionQuality,
      isAudioOnly: isAudioOnly ?? this.isAudioOnly,
      isMuted: isMuted ?? this.isMuted,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
    );
  }

  @override
  List<Object?> get props => [
    roomId,
    connectionQuality,
    isAudioOnly,
    isMuted,
    isCameraOff,
    reconnectAttempts,
  ];
}

class CallReconnecting extends CallState {
  final String roomId;
  final int attempt;
  final int maxAttempts;

  const CallReconnecting({
    required this.roomId,
    required this.attempt,
    this.maxAttempts = 3,
  });

  @override
  List<Object?> get props => [roomId, attempt, maxAttempts];
}

class CallEnded extends CallState {}

class CallFailure extends CallState {
  final String message;
  final bool canRetry;

  const CallFailure(this.message, {this.canRetry = false});

  @override
  List<Object?> get props => [message, canRetry];
}
