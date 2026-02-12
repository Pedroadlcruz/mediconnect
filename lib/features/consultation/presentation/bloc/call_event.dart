part of 'call_bloc.dart';

abstract class CallEvent extends Equatable {
  const CallEvent();

  @override
  List<Object?> get props => [];
}

class CallStarted extends CallEvent {
  final String? roomId; // null implies creating a room
  const CallStarted({this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class CallHungUp extends CallEvent {}

class ToggleCamera extends CallEvent {}

class ToggleMicrophone extends CallEvent {}

class SwitchCamera extends CallEvent {}

/// Internal event: ICE connection state changed
class _ConnectionStateChanged extends CallEvent {
  final RTCIceConnectionState iceState;
  const _ConnectionStateChanged(this.iceState);

  @override
  List<Object?> get props => [iceState];
}

/// User-triggered reconnection attempt
class CallReconnectRequested extends CallEvent {}

/// Fallback to audio-only mode
class CallFallbackToAudio extends CallEvent {}
