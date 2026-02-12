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
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('MediConnect')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Welcome to MediConnect'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.push('/pre-consultation'),
                child: const Text('Start Video Call'),
              ),
              const SizedBox(height: 20),
              // Input field for joining a room (for testing)
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Join Room ID (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      context.push('/pre-consultation?roomId=$value');
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.push('/prescription?roomId=test_room'),
                icon: const Icon(Icons.medical_services),
                label: const Text('Crear Receta (Test)'),
              ),
            ],
          ),
        ),
      ),
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
