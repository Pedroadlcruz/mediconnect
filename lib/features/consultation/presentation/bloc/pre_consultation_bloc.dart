import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:mediconnect/features/consultation/data/repositories/connection_repository_impl.dart';
import 'package:mediconnect/features/consultation/domain/entities/connection_status.dart';

part 'pre_consultation_event.dart';
part 'pre_consultation_state.dart';

@injectable
class PreConsultationBloc
    extends Bloc<PreConsultationEvent, PreConsultationState> {
  final ConnectionRepository _connectionRepository;

  PreConsultationBloc(this._connectionRepository)
    : super(PreConsultationInitial()) {
    on<StartConnectionCheck>(_onStartConnectionCheck);
  }

  Future<void> _onStartConnectionCheck(
    StartConnectionCheck event,
    Emitter<PreConsultationState> emit,
  ) async {
    emit(PreConsultationChecking());
    try {
      final status = await _connectionRepository.checkConnection();
      emit(PreConsultationReady(status));
    } catch (e) {
      emit(PreConsultationError(e.toString()));
    }
  }
}
