part of 'pre_consultation_bloc.dart';

abstract class PreConsultationEvent extends Equatable {
  const PreConsultationEvent();

  @override
  List<Object> get props => [];
}

class StartConnectionCheck extends PreConsultationEvent {}
