part of 'prescription_bloc.dart';

abstract class PrescriptionState extends Equatable {
  const PrescriptionState();
  @override
  List<Object?> get props => [];
}

class PrescriptionInitial extends PrescriptionState {}

class PrescriptionFormReady extends PrescriptionState {
  final Prescription? draft;

  const PrescriptionFormReady({this.draft});

  @override
  List<Object?> get props => [draft];
}

class PrescriptionAwaitingSignature extends PrescriptionState {
  final Prescription prescription;

  const PrescriptionAwaitingSignature(this.prescription);

  @override
  List<Object?> get props => [prescription];
}

class PrescriptionSaving extends PrescriptionState {}

class PrescriptionSaved extends PrescriptionState {
  final String prescriptionId;
  final bool isOffline;

  const PrescriptionSaved({
    required this.prescriptionId,
    this.isOffline = false,
  });

  @override
  List<Object?> get props => [prescriptionId, isOffline];
}

class PrescriptionLocalList extends PrescriptionState {
  final List<Prescription> prescriptions;

  const PrescriptionLocalList(this.prescriptions);

  @override
  List<Object?> get props => [prescriptions];
}

class PrescriptionError extends PrescriptionState {
  final String message;

  const PrescriptionError(this.message);

  @override
  List<Object?> get props => [message];
}

class PrescriptionSyncing extends PrescriptionState {}

class PrescriptionSynced extends PrescriptionState {}
