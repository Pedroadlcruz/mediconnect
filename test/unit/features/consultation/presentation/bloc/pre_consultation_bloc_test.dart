import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect/features/consultation/data/repositories/connection_repository_impl.dart';
import 'package:mediconnect/features/consultation/domain/entities/connection_status.dart';
import 'package:mediconnect/features/consultation/presentation/bloc/pre_consultation_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectionRepository extends Mock implements ConnectionRepository {}

void main() {
  late MockConnectionRepository mockConnectionRepository;

  setUp(() {
    mockConnectionRepository = MockConnectionRepository();
  });

  group('PreConsultationBloc', () {
    test('initial state is PreConsultationInitial', () {
      final bloc = PreConsultationBloc(mockConnectionRepository);
      expect(bloc.state, isA<PreConsultationInitial>());
      bloc.close();
    });

    blocTest<PreConsultationBloc, PreConsultationState>(
      'emits [Checking, Ready] when all checks pass',
      setUp: () {
        when(() => mockConnectionRepository.checkConnection()).thenAnswer(
          (_) async => const ConnectionStatus(
            hasInternet: true,
            hasCameraPermission: true,
            hasMicrophonePermission: true,
            isCameraAvailable: true,
            isMicrophoneAvailable: true,
          ),
        );
      },
      build: () => PreConsultationBloc(mockConnectionRepository),
      act: (bloc) => bloc.add(StartConnectionCheck()),
      expect: () => [
        isA<PreConsultationChecking>(),
        isA<PreConsultationReady>(),
      ],
      verify: (bloc) {
        final state = bloc.state as PreConsultationReady;
        expect(state.status.hasInternet, true);
        expect(state.status.hasCameraPermission, true);
        expect(state.status.hasMicrophonePermission, true);
        expect(state.status.isCameraAvailable, true);
        expect(state.status.isMicrophoneAvailable, true);
      },
    );

    blocTest<PreConsultationBloc, PreConsultationState>(
      'emits [Checking, Ready] even when some checks fail (UI shows partial)',
      setUp: () {
        when(() => mockConnectionRepository.checkConnection()).thenAnswer(
          (_) async => const ConnectionStatus(
            hasInternet: true,
            hasCameraPermission: false,
            hasMicrophonePermission: true,
            isCameraAvailable: false,
            isMicrophoneAvailable: true,
          ),
        );
      },
      build: () => PreConsultationBloc(mockConnectionRepository),
      act: (bloc) => bloc.add(StartConnectionCheck()),
      expect: () => [
        isA<PreConsultationChecking>(),
        isA<PreConsultationReady>(),
      ],
      verify: (bloc) {
        final state = bloc.state as PreConsultationReady;
        expect(state.status.hasInternet, true);
        expect(state.status.hasCameraPermission, false);
        expect(state.status.isCameraAvailable, false);
      },
    );

    blocTest<PreConsultationBloc, PreConsultationState>(
      'emits [Checking, Error] when checkConnection throws',
      setUp: () {
        when(
          () => mockConnectionRepository.checkConnection(),
        ).thenThrow(Exception('Hardware failure'));
      },
      build: () => PreConsultationBloc(mockConnectionRepository),
      act: (bloc) => bloc.add(StartConnectionCheck()),
      expect: () => [
        isA<PreConsultationChecking>(),
        isA<PreConsultationError>(),
      ],
    );
  });

  group('ConnectionStatus entity', () {
    test('isReady returns true when all checks pass', () {
      const status = ConnectionStatus(
        hasInternet: true,
        hasCameraPermission: true,
        hasMicrophonePermission: true,
        isCameraAvailable: true,
        isMicrophoneAvailable: true,
      );
      expect(status.isReady, true);
    });

    test('isReady returns false when internet is missing', () {
      const status = ConnectionStatus(
        hasInternet: false,
        hasCameraPermission: true,
        hasMicrophonePermission: true,
        isCameraAvailable: true,
        isMicrophoneAvailable: true,
      );
      expect(status.isReady, false);
    });

    test('isReady returns false when camera permission is missing', () {
      const status = ConnectionStatus(
        hasInternet: true,
        hasCameraPermission: false,
        hasMicrophonePermission: true,
        isCameraAvailable: true,
        isMicrophoneAvailable: true,
      );
      expect(status.isReady, false);
    });

    test('isReady returns false when microphone is not available', () {
      const status = ConnectionStatus(
        hasInternet: true,
        hasCameraPermission: true,
        hasMicrophonePermission: true,
        isCameraAvailable: true,
        isMicrophoneAvailable: false,
      );
      expect(status.isReady, false);
    });
  });
}
