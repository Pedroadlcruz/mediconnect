import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect/features/consultation/presentation/bloc/call_bloc.dart';

/// CallBloc tests
///
/// Note: Tests that instantiate CallBloc directly are skipped because
/// RTCVideoRenderer requires native platform bindings that are not
/// available in the Flutter test environment. These tests should be
/// run as integration tests on a real device/emulator.

void main() {
  group('CallBloc States', () {
    test('CallReconnecting state contains correct attempt info', () {
      const state = CallReconnecting(
        roomId: 'test-room',
        attempt: 2,
        maxAttempts: 3,
      );
      expect(state.attempt, 2);
      expect(state.maxAttempts, 3);
      expect(state.roomId, 'test-room');
    });

    test('CallReconnecting defaults maxAttempts to 3', () {
      const state = CallReconnecting(roomId: 'room', attempt: 1);
      expect(state.maxAttempts, 3);
    });

    test('CallFailure canRetry defaults to false', () {
      const failure = CallFailure('test error');
      expect(failure.canRetry, false);
      expect(failure.message, 'test error');
    });

    test('CallFailure canRetry can be set to true', () {
      const failure = CallFailure('connection lost', canRetry: true);
      expect(failure.canRetry, true);
    });

    test('CallFailure equality based on message and canRetry', () {
      const f1 = CallFailure('error', canRetry: true);
      const f2 = CallFailure('error', canRetry: true);
      const f3 = CallFailure('error', canRetry: false);
      expect(f1, equals(f2));
      expect(f1, isNot(equals(f3)));
    });
  });

  group('ConnectionQuality enum', () {
    test('has all expected values', () {
      expect(ConnectionQuality.values.length, 5);
      expect(
        ConnectionQuality.values,
        containsAll([
          ConnectionQuality.excellent,
          ConnectionQuality.good,
          ConnectionQuality.poor,
          ConnectionQuality.disconnected,
          ConnectionQuality.reconnecting,
        ]),
      );
    });

    test('ordering is correct', () {
      expect(ConnectionQuality.excellent.index, 0);
      expect(ConnectionQuality.good.index, 1);
      expect(ConnectionQuality.poor.index, 2);
      expect(ConnectionQuality.disconnected.index, 3);
      expect(ConnectionQuality.reconnecting.index, 4);
    });
  });

  group('CallBloc BlocTests (skipped - requires native WebRTC)', () {
    // These tests require native WebRTC bindings and should be run
    // as integration tests on a real device/emulator.
    test(
      'CallStarted emits [CallLoading, then Ready or Failure]',
      skip: 'Requires native WebRTC bindings — run as integration test',
      () {},
    );

    test(
      'CallHungUp cleans up resources and emits CallEnded',
      skip: 'Requires native WebRTC bindings — run as integration test',
      () {},
    );

    test(
      'CallReconnectRequested recreates peer connection',
      skip: 'Requires native WebRTC bindings — run as integration test',
      () {},
    );

    test(
      'CallFallbackToAudio switches to audio-only mode',
      skip: 'Requires native WebRTC bindings — run as integration test',
      () {},
    );
  });
}
