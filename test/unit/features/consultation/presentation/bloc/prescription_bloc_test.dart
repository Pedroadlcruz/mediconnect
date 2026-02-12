import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect/features/consultation/data/data_sources/prescription_service.dart';
import 'package:mediconnect/features/consultation/data/models/prescription_model.dart';
import 'package:mediconnect/features/consultation/domain/entities/prescription.dart';
import 'package:mediconnect/features/consultation/presentation/bloc/prescription_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockPrescriptionService extends Mock implements PrescriptionService {}

class FakePrescriptionModel extends Fake implements PrescriptionModel {}

void main() {
  late MockPrescriptionService mockPrescriptionService;

  setUpAll(() {
    registerFallbackValue(FakePrescriptionModel());
  });

  setUp(() {
    mockPrescriptionService = MockPrescriptionService();
  });

  group('PrescriptionBloc', () {
    test('initial state is PrescriptionInitial', () {
      final bloc = PrescriptionBloc(mockPrescriptionService);
      expect(bloc.state, isA<PrescriptionInitial>());
      bloc.close();
    });

    blocTest<PrescriptionBloc, PrescriptionState>(
      'emits [PrescriptionAwaitingSignature] when form is submitted',
      build: () => PrescriptionBloc(mockPrescriptionService),
      act: (bloc) => bloc.add(
        const PrescriptionFormSubmitted(
          roomId: 'room_1',
          doctorId: 'doctor_1',
          doctorName: 'Dr. García',
          patientId: 'patient_1',
          patientName: 'Juan Pérez',
          diagnosis: 'Gripe común',
          medications: ['Paracetamol 500mg'],
          instructions: 'Tomar cada 8 horas',
        ),
      ),
      expect: () => [isA<PrescriptionAwaitingSignature>()],
      verify: (bloc) {
        final state = bloc.state as PrescriptionAwaitingSignature;
        expect(state.prescription.diagnosis, 'Gripe común');
        expect(state.prescription.medications, ['Paracetamol 500mg']);
        expect(state.prescription.doctorName, 'Dr. García');
        expect(state.prescription.patientName, 'Juan Pérez');
      },
    );

    blocTest<PrescriptionBloc, PrescriptionState>(
      'emits [PrescriptionAwaitingSignature] with signature after PrescriptionSigned',
      build: () => PrescriptionBloc(mockPrescriptionService),
      act: (bloc) {
        // First submit form
        bloc.add(
          const PrescriptionFormSubmitted(
            roomId: 'room_1',
            doctorId: 'doctor_1',
            doctorName: 'Dr. García',
            patientId: 'patient_1',
            patientName: 'Juan Pérez',
            diagnosis: 'Gripe',
            medications: ['Med1'],
            instructions: 'Instrucciones',
          ),
        );
        // Then sign
        bloc.add(const PrescriptionSigned('base64_signature_data'));
      },
      expect: () => [
        isA<PrescriptionAwaitingSignature>(), // After form submit
        isA<PrescriptionAwaitingSignature>(), // After signing
      ],
    );

    blocTest<PrescriptionBloc, PrescriptionState>(
      'emits [PrescriptionError] when trying to sign without a draft',
      build: () => PrescriptionBloc(mockPrescriptionService),
      act: (bloc) => bloc.add(const PrescriptionSigned('signature')),
      expect: () => [isA<PrescriptionError>()],
      verify: (bloc) {
        expect(
          (bloc.state as PrescriptionError).message,
          'No hay receta en borrador',
        );
      },
    );

    blocTest<PrescriptionBloc, PrescriptionState>(
      'emits [PrescriptionError] when trying to save without signature',
      build: () => PrescriptionBloc(mockPrescriptionService),
      act: (bloc) {
        // Submit form but don't sign
        bloc.add(
          const PrescriptionFormSubmitted(
            roomId: 'room_1',
            doctorId: 'doctor_1',
            doctorName: 'Dr. García',
            patientId: 'patient_1',
            patientName: 'Juan Pérez',
            diagnosis: 'Gripe',
            medications: ['Med1'],
            instructions: 'Instrucciones',
          ),
        );
        // Try to save without signing
        bloc.add(const PrescriptionSaveRequested());
      },
      expect: () => [
        isA<PrescriptionAwaitingSignature>(),
        isA<PrescriptionError>(),
      ],
    );

    blocTest<PrescriptionBloc, PrescriptionState>(
      'emits [PrescriptionSaving, PrescriptionSaved] on successful online save',
      setUp: () {
        when(
          () => mockPrescriptionService.savePrescription(any()),
        ).thenAnswer((_) async => 'firestore_doc_id');
      },
      build: () => PrescriptionBloc(mockPrescriptionService),
      act: (bloc) {
        bloc.add(
          const PrescriptionFormSubmitted(
            roomId: 'room_1',
            doctorId: 'doctor_1',
            doctorName: 'Dr. García',
            patientId: 'patient_1',
            patientName: 'Juan Pérez',
            diagnosis: 'Gripe',
            medications: ['Med1'],
            instructions: 'Instrucciones',
          ),
        );
        bloc.add(const PrescriptionSigned('base64_sig'));
        bloc.add(const PrescriptionSaveRequested());
      },
      expect: () => [
        isA<PrescriptionAwaitingSignature>(), // Form submitted
        isA<PrescriptionAwaitingSignature>(), // Signed
        isA<PrescriptionSaving>(), // Saving
        isA<PrescriptionSaved>(), // Saved
      ],
      verify: (bloc) {
        final state = bloc.state as PrescriptionSaved;
        expect(state.prescriptionId, 'firestore_doc_id');
        expect(state.isOffline, false);
      },
    );

    blocTest<PrescriptionBloc, PrescriptionState>(
      'emits [PrescriptionSaving, PrescriptionSaved(offline)] on offline save',
      setUp: () {
        when(
          () => mockPrescriptionService.savePrescriptionLocally(any()),
        ).thenAnswer((_) async {});
      },
      build: () => PrescriptionBloc(mockPrescriptionService),
      act: (bloc) {
        bloc.add(
          const PrescriptionFormSubmitted(
            roomId: 'room_1',
            doctorId: 'doctor_1',
            doctorName: 'Dr. García',
            patientId: 'patient_1',
            patientName: 'Juan Pérez',
            diagnosis: 'Gripe',
            medications: ['Med1'],
            instructions: 'Instrucciones',
          ),
        );
        bloc.add(const PrescriptionSigned('base64_sig'));
        bloc.add(const PrescriptionSaveRequested(isOffline: true));
      },
      expect: () => [
        isA<PrescriptionAwaitingSignature>(),
        isA<PrescriptionAwaitingSignature>(),
        isA<PrescriptionSaving>(),
        isA<PrescriptionSaved>(),
      ],
      verify: (bloc) {
        final state = bloc.state as PrescriptionSaved;
        expect(state.isOffline, true);
        verify(
          () => mockPrescriptionService.savePrescriptionLocally(any()),
        ).called(1);
      },
    );

    blocTest<PrescriptionBloc, PrescriptionState>(
      'falls back to offline save when online save fails',
      setUp: () {
        when(
          () => mockPrescriptionService.savePrescription(any()),
        ).thenThrow(Exception('Network error'));
        when(
          () => mockPrescriptionService.savePrescriptionLocally(any()),
        ).thenAnswer((_) async {});
      },
      build: () => PrescriptionBloc(mockPrescriptionService),
      act: (bloc) {
        bloc.add(
          const PrescriptionFormSubmitted(
            roomId: 'room_1',
            doctorId: 'doctor_1',
            doctorName: 'Dr. García',
            patientId: 'patient_1',
            patientName: 'Juan Pérez',
            diagnosis: 'Gripe',
            medications: ['Med1'],
            instructions: 'Instrucciones',
          ),
        );
        bloc.add(const PrescriptionSigned('base64_sig'));
        bloc.add(const PrescriptionSaveRequested());
      },
      expect: () => [
        isA<PrescriptionAwaitingSignature>(),
        isA<PrescriptionAwaitingSignature>(),
        isA<PrescriptionSaving>(),
        isA<PrescriptionSaved>(), // Falls back to offline
      ],
      verify: (bloc) {
        final state = bloc.state as PrescriptionSaved;
        expect(state.isOffline, true);
        verify(
          () => mockPrescriptionService.savePrescriptionLocally(any()),
        ).called(1);
      },
    );

    blocTest<PrescriptionBloc, PrescriptionState>(
      'emits [PrescriptionLocalList] when loading local prescriptions',
      setUp: () {
        when(() => mockPrescriptionService.getLocalPrescriptions()).thenAnswer(
          (_) async => [
            Prescription(
              id: 'local_1',
              roomId: 'room_1',
              doctorId: 'doc_1',
              doctorName: 'Dr. Test',
              patientId: 'pat_1',
              patientName: 'Patient',
              diagnosis: 'Test',
              medications: const ['Med'],
              instructions: 'Instructions',
              createdAt: DateTime(2026, 2, 12),
              isSynced: false,
            ),
          ],
        );
      },
      build: () => PrescriptionBloc(mockPrescriptionService),
      act: (bloc) => bloc.add(const PrescriptionLoadLocal()),
      expect: () => [isA<PrescriptionLocalList>()],
      verify: (bloc) {
        final state = bloc.state as PrescriptionLocalList;
        expect(state.prescriptions.length, 1);
        expect(state.prescriptions[0].isSynced, false);
      },
    );

    blocTest<PrescriptionBloc, PrescriptionState>(
      'emits [PrescriptionSyncing, PrescriptionSynced] on successful sync',
      setUp: () {
        when(
          () => mockPrescriptionService.syncPendingPrescriptions(),
        ).thenAnswer((_) async {});
      },
      build: () => PrescriptionBloc(mockPrescriptionService),
      act: (bloc) => bloc.add(const PrescriptionSyncRequested()),
      expect: () => [isA<PrescriptionSyncing>(), isA<PrescriptionSynced>()],
    );

    blocTest<PrescriptionBloc, PrescriptionState>(
      'emits [PrescriptionSyncing, PrescriptionError] when sync fails',
      setUp: () {
        when(
          () => mockPrescriptionService.syncPendingPrescriptions(),
        ).thenThrow(Exception('Sync failed'));
      },
      build: () => PrescriptionBloc(mockPrescriptionService),
      act: (bloc) => bloc.add(const PrescriptionSyncRequested()),
      expect: () => [isA<PrescriptionSyncing>(), isA<PrescriptionError>()],
    );
  });

  group('Prescription entity', () {
    test('isSigned returns false when signatureBase64 is null', () {
      final p = Prescription(
        id: '1',
        roomId: 'room',
        doctorId: 'doc',
        doctorName: 'Dr',
        patientId: 'pat',
        patientName: 'Patient',
        diagnosis: 'dx',
        medications: const ['med'],
        instructions: 'inst',
        createdAt: DateTime.now(),
      );
      expect(p.isSigned, false);
    });

    test('isSigned returns true when signatureBase64 is set', () {
      final p = Prescription(
        id: '1',
        roomId: 'room',
        doctorId: 'doc',
        doctorName: 'Dr',
        patientId: 'pat',
        patientName: 'Patient',
        diagnosis: 'dx',
        medications: const ['med'],
        instructions: 'inst',
        signatureBase64: 'base64data',
        createdAt: DateTime.now(),
      );
      expect(p.isSigned, true);
    });

    test('copyWith creates new instance with updated fields', () {
      final p = Prescription(
        id: '1',
        roomId: 'room',
        doctorId: 'doc',
        doctorName: 'Dr',
        patientId: 'pat',
        patientName: 'Patient',
        diagnosis: 'dx',
        medications: const ['med'],
        instructions: 'inst',
        createdAt: DateTime(2026, 1, 1),
        isSynced: false,
      );

      final updated = p.copyWith(signatureBase64: 'new_sig', isSynced: true);
      expect(updated.signatureBase64, 'new_sig');
      expect(updated.isSynced, true);
      expect(updated.diagnosis, 'dx'); // Unchanged
      expect(updated.id, '1');
    });
  });
}
