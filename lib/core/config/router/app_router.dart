import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect/features/consultation/presentation/pages/call_screen.dart';
import 'package:mediconnect/features/consultation/presentation/pages/pre_consultation_page.dart';
import 'package:mediconnect/features/consultation/presentation/pages/prescription_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        final roomIdController = TextEditingController();
        return Scaffold(
          appBar: AppBar(
            title: const Text('MediConnect'),
            centerTitle: true,
            backgroundColor: const Color(0xFF2C3E50),
            foregroundColor: Colors.white,
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam, size: 64, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'MediConnect',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Consultas médicas por videollamada',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 40),

                    // ── OPTION 1: Create Room ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '📞 Iniciar Llamada',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Crea una sala y comparte el ID generado con la otra persona.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  context.push('/pre-consultation'),
                              icon: const Icon(Icons.video_call),
                              label: const Text('Crear Sala'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00BFA5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── OPTION 2: Join Room ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '🔗 Unirse a Llamada',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ingresa el Room ID que te compartieron.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: roomIdController,
                            decoration: InputDecoration(
                              labelText: 'Room ID',
                              hintText: 'Ej: abc123xyz',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.meeting_room),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final id = roomIdController.text.trim();
                                if (id.isNotEmpty) {
                                  context.push('/pre-consultation?roomId=$id');
                                }
                              },
                              icon: const Icon(Icons.login),
                              label: const Text('Unirse'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3498DB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Prescription test (optional) ──
                    TextButton.icon(
                      onPressed: () =>
                          context.push('/prescription?roomId=test_room'),
                      icon: const Icon(
                        Icons.medical_services,
                        color: Colors.white70,
                      ),
                      label: const Text(
                        'Crear Receta (Test)',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: '/pre-consultation',
      builder: (context, state) {
        final roomId = state.uri.queryParameters['roomId'];
        return PreConsultationPage(roomId: roomId);
      },
    ),
    GoRoute(
      path: '/call',
      builder: (context, state) {
        final roomId = state.uri.queryParameters['roomId'];
        return CallScreen(roomId: roomId);
      },
    ),
    GoRoute(
      path: '/prescription',
      builder: (context, state) {
        final roomId = state.uri.queryParameters['roomId'] ?? '';
        return PrescriptionPage(roomId: roomId);
      },
    ),
  ],
);
