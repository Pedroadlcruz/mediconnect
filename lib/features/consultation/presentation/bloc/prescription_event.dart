part of 'prescription_bloc.dart';

abstract class PrescriptionEvent extends Equatable {
  const PrescriptionEvent();
  @override
  List<Object?> get props => [];
}

class PrescriptionFormSubmitted extends PrescriptionEvent {
  final String roomId;
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String patientName;
  final String diagnosis;
  final List<String> medications;
  final String instructions;

  const PrescriptionFormSubmitted({
    required this.roomId,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    required this.diagnosis,
    required this.medications,
    required this.instructions,
  });

  @override
  List<Object?> get props => [roomId, diagnosis, medications];
}

class PrescriptionSigned extends PrescriptionEvent {
  final String signatureBase64;

  const PrescriptionSigned(this.signatureBase64);

  @override
  List<Object?> get props => [signatureBase64];
}

class PrescriptionSaveRequested extends PrescriptionEvent {
  final bool isOffline;

  const PrescriptionSaveRequested({this.isOffline = false});

  @override
  List<Object?> get props => [isOffline];
}

class PrescriptionLoadLocal extends PrescriptionEvent {
  const PrescriptionLoadLocal();
}

class PrescriptionSyncRequested extends PrescriptionEvent {
  const PrescriptionSyncRequested();
}
