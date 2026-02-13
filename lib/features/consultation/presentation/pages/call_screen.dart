import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect/core/di/service_locator.dart';
import 'package:mediconnect/features/consultation/presentation/bloc/call_bloc.dart';
import 'package:mediconnect/features/consultation/presentation/bloc/chat_bloc.dart';
import 'package:mediconnect/features/consultation/presentation/widgets/chat_overlay.dart';

class CallScreen extends StatelessWidget {
  final String? roomId;

  const CallScreen({super.key, this.roomId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              getIt<CallBloc>()..add(CallStarted(roomId: roomId)),
        ),
        BlocProvider(create: (context) => getIt<ChatBloc>()),
      ],
      child: const _CallView(),
    );
  }
}

class _CallView extends StatelessWidget {
  const _CallView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<CallBloc, CallState>(
        listener: (context, state) {
          if (state is CallReady) {
            // Initialize chat when call is ready
            context.read<ChatBloc>().add(
              ChatStarted(
                roomId: state.roomId,
                currentUserId: 'user_${DateTime.now().millisecondsSinceEpoch}',
                currentUserName: 'Usuario',
              ),
            );
          }
          if (state is CallEnded) {
            context.pop();
          }
          if (state is CallFailure && !state.canRetry) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
            context.pop();
          }
        },
        builder: (context, state) {
          if (state is CallLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Conectando...', style: TextStyle(color: Colors.white)),
                ],
              ),
            );
          }

          if (state is CallReconnecting) {
            return _ReconnectingView(
              attempt: state.attempt,
              maxAttempts: state.maxAttempts,
            );
          }

          if (state is CallFailure && state.canRetry) {
            return _ConnectionFailureView(message: state.message);
          }

          if (state is CallReady) {
            return Stack(
              children: [
                // Remote Video or Audio-Only Background
                if (!state.isAudioOnly)
                  Positioned.fill(
                    child: RTCVideoView(
                      state.remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  )
                else
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_in_talk,
                            size: 80,
                            color: Colors.white54,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Modo Solo Audio',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'La videollamada se cambió a audio por problemas de conexión',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Local Video (only when not audio-only)
                if (!state.isAudioOnly)
                  Positioned(
                    right: 20,
                    top: 50,
                    width: 100,
                    height: 150,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: RTCVideoView(
                          state.localRenderer,
                          mirror: true,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      ),
                    ),
                  ),

                // Connection Quality Indicator
                Positioned(
                  top: 50,
                  left: 20,
                  child: _ConnectionQualityBadge(
                    quality: state.connectionQuality,
                    isAudioOnly: state.isAudioOnly,
                    roomId: state.roomId,
                  ),
                ),

                // Room ID Display (so caller can share it)
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: state.roomId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Room ID copiado: ${state.roomId}'),
                            duration: const Duration(seconds: 5),
                            backgroundColor: const Color(0xFF2C3E50),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ID: ${state.roomId.length > 8 ? '${state.roomId.substring(0, 8)}...' : state.roomId}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _CallControls(
                        roomId: state.roomId,
                        isAudioOnly: state.isAudioOnly,
                        isMuted: state.isMuted,
                        isCameraOff: state.isCameraOff,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(
            child: Text(
              'Inicializando...',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}

// ─── Connection Quality Badge ───
class _ConnectionQualityBadge extends StatelessWidget {
  final ConnectionQuality quality;
  final bool isAudioOnly;
  final String roomId;

  const _ConnectionQualityBadge({
    required this.quality,
    required this.isAudioOnly,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (quality) {
      ConnectionQuality.excellent => (
        Icons.signal_cellular_4_bar,
        Colors.green,
        'Excelente',
      ),
      ConnectionQuality.good => (
        Icons.signal_cellular_alt,
        Colors.lightGreen,
        'Buena',
      ),
      ConnectionQuality.poor => (
        Icons.signal_cellular_alt_1_bar,
        Colors.orange,
        'Débil',
      ),
      ConnectionQuality.disconnected => (
        Icons.signal_cellular_off,
        Colors.red,
        'Sin conexión',
      ),
      ConnectionQuality.reconnecting => (
        Icons.sync,
        Colors.amber,
        'Reconectando...',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isAudioOnly) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '🎤 Audio',
                style: TextStyle(color: Colors.amber, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Reconnecting View ───
class _ReconnectingView extends StatelessWidget {
  final int attempt;
  final int maxAttempts;

  const _ReconnectingView({required this.attempt, required this.maxAttempts});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: Colors.amber,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Reconectando...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Intento $attempt de $maxAttempts',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'La conexión se interrumpió. Intentando restablecer automáticamente.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: () => context.read<CallBloc>().add(CallHungUp()),
              icon: const Icon(Icons.call_end, color: Colors.red),
              label: const Text(
                'Finalizar Llamada',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Connection Failure View (with retry / fallback options) ───
class _ConnectionFailureView extends StatelessWidget {
  final String message;

  const _ConnectionFailureView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.signal_wifi_off, size: 72, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Problema de Conexión',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Fallback to audio button
              ElevatedButton.icon(
                onPressed: () =>
                    context.read<CallBloc>().add(CallFallbackToAudio()),
                icon: const Icon(Icons.phone_in_talk),
                label: const Text(
                  'Continuar con Solo Audio',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Retry with video
              OutlinedButton.icon(
                onPressed: () =>
                    context.read<CallBloc>().add(CallReconnectRequested()),
                icon: const Icon(Icons.refresh, color: Colors.white70),
                label: const Text(
                  'Reintentar con Video',
                  style: TextStyle(color: Colors.white70),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  side: const BorderSide(color: Colors.white38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.read<CallBloc>().add(CallHungUp()),
                icon: const Icon(Icons.call_end, color: Colors.red),
                label: const Text(
                  'Finalizar Llamada',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Call Controls ───
class _CallControls extends StatelessWidget {
  final String roomId;
  final bool isAudioOnly;
  final bool isMuted;
  final bool isCameraOff;

  const _CallControls({
    required this.roomId,
    required this.isAudioOnly,
    this.isMuted = false,
    this.isCameraOff = false,
  });

  @override
  Widget build(BuildContext context) {
    final callBloc = context.read<CallBloc>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton(
          heroTag: 'mic',
          onPressed: () => callBloc.add(ToggleMicrophone()),
          backgroundColor: isMuted ? Colors.red : Colors.white,
          child: Icon(
            isMuted ? Icons.mic_off : Icons.mic,
            color: isMuted ? Colors.white : Colors.black,
          ),
        ),
        FloatingActionButton(
          heroTag: 'chat',
          onPressed: () => _openChat(context),
          backgroundColor: Colors.white,
          child: const Icon(Icons.chat, color: Colors.black),
        ),
        FloatingActionButton(
          heroTag: 'end',
          onPressed: () => callBloc.add(CallHungUp()),
          backgroundColor: Colors.red,
          child: const Icon(Icons.call_end),
        ),
        if (!isAudioOnly) ...[
          FloatingActionButton(
            heroTag: 'cam',
            onPressed: () => callBloc.add(ToggleCamera()),
            backgroundColor: isCameraOff ? Colors.red : Colors.white,
            child: Icon(
              isCameraOff ? Icons.videocam_off : Icons.videocam,
              color: isCameraOff ? Colors.white : Colors.black,
            ),
          ),
          FloatingActionButton(
            heroTag: 'switch',
            mini: true,
            onPressed: () => callBloc.add(SwitchCamera()),
            backgroundColor: Colors.blueGrey,
            child: const Icon(Icons.cameraswitch, size: 20),
          ),
        ],
      ],
    );
  }

  void _openChat(BuildContext context) {
    final chatBloc = context.read<ChatBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          BlocProvider.value(value: chatBloc, child: const ChatOverlay()),
    );
  }
}
