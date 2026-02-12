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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4CA1AF), Color(0xFF2C3E50)],
        ),
      ),
      child: BlocBuilder<PreConsultationBloc, PreConsultationState>(
        builder: (context, state) {
          if (state is PreConsultationChecking) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'Verificando conexión y permisos...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            );
          } else if (state is PreConsultationReady) {
            final status = state.status;
            final allGood = status.isReady;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Preparando Consulta',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2C3E50),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Por favor verifique que todo funcione correctamente antes de ingresar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 30),
                          _StatusItem(
                            label: 'Conexión a Internet',
                            isOk: status.hasInternet,
                            icon: Icons.wifi,
                          ),
                          _StatusItem(
                            label: 'Permiso de Cámara',
                            isOk: status.hasCameraPermission,
                            icon: Icons.camera_alt,
                          ),
                          _StatusItem(
                            label: 'Permiso de Micrófono',
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
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
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: const Color(0xFF00BFA5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Unirse a la Llamada',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.video_call, color: Colors.white),
                          ],
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
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: Colors.orangeAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Reintentar Verificación',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          } else if (state is PreConsultationError) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ocurrió un error',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<PreConsultationBloc>().add(
                          StartConnectionCheck(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          return Container();
        },
      ),
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
