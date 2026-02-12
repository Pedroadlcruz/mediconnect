import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:mediconnect/features/consultation/data/data_sources/prescription_service.dart';
import 'package:mediconnect/features/consultation/data/models/prescription_model.dart';
import 'package:mediconnect/features/consultation/domain/entities/prescription.dart';

part 'prescription_event.dart';
part 'prescription_state.dart';

@injectable
class PrescriptionBloc extends Bloc<PrescriptionEvent, PrescriptionState> {
  final PrescriptionService _prescriptionService;
  Prescription? _currentDraft;

  PrescriptionBloc(this._prescriptionService) : super(PrescriptionInitial()) {
    on<PrescriptionFormSubmitted>(_onFormSubmitted);
    on<PrescriptionSigned>(_onSigned);
    on<PrescriptionSaveRequested>(_onSaveRequested);
    on<PrescriptionLoadLocal>(_onLoadLocal);
    on<PrescriptionSyncRequested>(_onSyncRequested);
  }

  void _onFormSubmitted(
    PrescriptionFormSubmitted event,
    Emitter<PrescriptionState> emit,
  ) {
    _currentDraft = Prescription(
      id: '',
      roomId: event.roomId,
      doctorId: event.doctorId,
      doctorName: event.doctorName,
      patientId: event.patientId,
      patientName: event.patientName,
      diagnosis: event.diagnosis,
      medications: event.medications,
      instructions: event.instructions,
      createdAt: DateTime.now(),
    );
    emit(PrescriptionAwaitingSignature(_currentDraft!));
  }

  void _onSigned(PrescriptionSigned event, Emitter<PrescriptionState> emit) {
    if (_currentDraft == null) {
      emit(const PrescriptionError('No hay receta en borrador'));
      return;
    }
    _currentDraft = _currentDraft!.copyWith(
      signatureBase64: event.signatureBase64,
    );
    emit(PrescriptionAwaitingSignature(_currentDraft!));
  }

  Future<void> _onSaveRequested(
    PrescriptionSaveRequested event,
    Emitter<PrescriptionState> emit,
  ) async {
    if (_currentDraft == null || !_currentDraft!.isSigned) {
      emit(
        const PrescriptionError(
          'La receta debe estar firmada antes de guardar',
        ),
      );
      return;
    }

    emit(PrescriptionSaving());

    try {
      final model = PrescriptionModel(
        id: _currentDraft!.id,
        roomId: _currentDraft!.roomId,
        doctorId: _currentDraft!.doctorId,
        doctorName: _currentDraft!.doctorName,
        patientId: _currentDraft!.patientId,
        patientName: _currentDraft!.patientName,
        diagnosis: _currentDraft!.diagnosis,
        medications: _currentDraft!.medications,
        instructions: _currentDraft!.instructions,
        signatureBase64: _currentDraft!.signatureBase64,
        createdAt: _currentDraft!.createdAt,
        isSynced: !event.isOffline,
      );

      if (event.isOffline) {
        await _prescriptionService.savePrescriptionLocally(model);
        emit(
          PrescriptionSaved(
            prescriptionId: model.id.isNotEmpty
                ? model.id
                : 'local_${DateTime.now().millisecondsSinceEpoch}',
            isOffline: true,
          ),
        );
      } else {
        final docId = await _prescriptionService.savePrescription(model);
        emit(PrescriptionSaved(prescriptionId: docId));
      }
      _currentDraft = null;
    } catch (e) {
      // Fallback: save offline if online fails
      try {
        final model = PrescriptionModel(
          id: '',
          roomId: _currentDraft!.roomId,
          doctorId: _currentDraft!.doctorId,
          doctorName: _currentDraft!.doctorName,
          patientId: _currentDraft!.patientId,
          patientName: _currentDraft!.patientName,
          diagnosis: _currentDraft!.diagnosis,
          medications: _currentDraft!.medications,
          instructions: _currentDraft!.instructions,
          signatureBase64: _currentDraft!.signatureBase64,
          createdAt: _currentDraft!.createdAt,
          isSynced: false,
        );
        await _prescriptionService.savePrescriptionLocally(model);
        emit(
          PrescriptionSaved(
            prescriptionId: 'local_${DateTime.now().millisecondsSinceEpoch}',
            isOffline: true,
          ),
        );
        _currentDraft = null;
      } catch (e2) {
        emit(PrescriptionError(e2.toString()));
      }
    }
  }

  Future<void> _onLoadLocal(
    PrescriptionLoadLocal event,
    Emitter<PrescriptionState> emit,
  ) async {
    try {
      final prescriptions = await _prescriptionService.getLocalPrescriptions();
      emit(PrescriptionLocalList(prescriptions));
    } catch (e) {
      emit(PrescriptionError(e.toString()));
    }
  }

  Future<void> _onSyncRequested(
    PrescriptionSyncRequested event,
    Emitter<PrescriptionState> emit,
  ) async {
    emit(PrescriptionSyncing());
    try {
      await _prescriptionService.syncPendingPrescriptions();
      emit(PrescriptionSynced());
    } catch (e) {
      emit(PrescriptionError('Error al sincronizar: ${e.toString()}'));
    }
  }
}
