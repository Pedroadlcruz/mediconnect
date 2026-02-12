part of 'pre_consultation_bloc.dart';

abstract class PreConsultationState extends Equatable {
  const PreConsultationState();

  @override
  List<Object> get props => [];
}

class PreConsultationInitial extends PreConsultationState {}

class PreConsultationChecking extends PreConsultationState {}

class PreConsultationReady extends PreConsultationState {
  final ConnectionStatus status;

  const PreConsultationReady(this.status);

  @override
  List<Object> get props => [status];
}

class PreConsultationError extends PreConsultationState {
  final String message;

  const PreConsultationError(this.message);

  @override
  List<Object> get props => [message];
}
