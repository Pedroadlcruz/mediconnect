import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect/core/di/service_locator.dart';
import 'package:mediconnect/features/consultation/presentation/bloc/pre_consultation_bloc.dart';

class PreConsultationPage extends StatelessWidget {
  final String? roomId;

  const PreConsultationPage({super.key, this.roomId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<PreConsultationBloc>()..add(StartConnectionCheck()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Sala de Espera')),
        body: _PreConsultationBody(roomId: roomId),
      ),
    );
  }
}

class _PreConsultationBody extends StatelessWidget {
  final String? roomId;

  const _PreConsultationBody({this.roomId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreConsultationBloc, PreConsultationState>(
      builder: (context, state) {
        if (state is PreConsultationChecking) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Verificando conexión y permisos...'),
              ],
            ),
          );
        } else if (state is PreConsultationReady) {
          final status = state.status;
          final allGood = status.isReady;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Comprobación de Sistema',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _StatusItem(
                  label: 'Conexión a Internet',
                  isOk: status.hasInternet,
                  icon: Icons.wifi,
                ),
                _StatusItem(
                  label: 'Cámara (Permiso)',
                  isOk: status.hasCameraPermission,
                  icon: Icons.camera_alt,
                ),
                _StatusItem(
                  label: 'Micrófono (Permiso)',
                  isOk: status.hasMicrophonePermission,
                  icon: Icons.mic,
                ),
                _StatusItem(
                  label: 'Cámara Disponible',
                  isOk: status.isCameraAvailable,
                  icon: Icons.videocam,
                ),
                _StatusItem(
                  label: 'Micrófono Disponible',
                  isOk: status.isMicrophoneAvailable,
                  icon: Icons.mic_none,
                ),
                const Spacer(),
                if (allGood)
                  ElevatedButton(
                    onPressed: () {
                      String path = '/call';
                      if (roomId != null && roomId!.isNotEmpty) {
                        path += '?roomId=$roomId';
                      }
                      context.push(path);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Iniciar Consulta',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      context.read<PreConsultationBloc>().add(
                        StartConnectionCheck(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text(
                      'Reintentar Verificación',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
              ],
            ),
          );
        } else if (state is PreConsultationError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${state.message}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<PreConsultationBloc>().add(
                      StartConnectionCheck(),
                    );
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        return Container();
      },
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final bool isOk;
  final IconData icon;

  const _StatusItem({
    required this.label,
    required this.isOk,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: isOk ? Colors.green : Colors.grey),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Icon(
            isOk ? Icons.check_circle : Icons.cancel,
            color: isOk ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }
}
