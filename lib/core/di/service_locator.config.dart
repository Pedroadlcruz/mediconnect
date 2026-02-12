// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/auth/data/data_sources/auth_remote_data_source.dart'
    as _i25;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/consultation/data/data_sources/chat_service.dart'
    as _i718;
import '../../features/consultation/data/data_sources/connection_audit_service.dart'
    as _i558;
import '../../features/consultation/data/data_sources/prescription_service.dart'
    as _i976;
import '../../features/consultation/data/data_sources/signaling_bridge.dart'
    as _i215;
import '../../features/consultation/data/repositories/connection_repository_impl.dart'
    as _i995;
import '../../features/consultation/presentation/bloc/call_bloc.dart' as _i156;
import '../../features/consultation/presentation/bloc/chat_bloc.dart' as _i806;
import '../../features/consultation/presentation/bloc/pre_consultation_bloc.dart'
    as _i206;
import '../../features/consultation/presentation/bloc/prescription_bloc.dart'
    as _i349;
import 'firebase_module.dart' as _i616;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final firebaseModule = _$FirebaseModule();
    gh.lazySingleton<_i59.FirebaseAuth>(() => firebaseModule.firebaseAuth);
    gh.lazySingleton<_i974.FirebaseFirestore>(() => firebaseModule.firestore);
    gh.lazySingleton<_i558.ConnectionAuditService>(
      () => _i558.ConnectionAuditServiceImpl(),
    );
    gh.lazySingleton<_i718.ChatService>(
      () => _i718.ChatServiceImpl(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i976.PrescriptionService>(
      () => _i976.PrescriptionServiceImpl(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i25.AuthRemoteDataSource>(
      () => _i25.AuthRemoteDataSourceImpl(gh<_i59.FirebaseAuth>()),
    );
    gh.lazySingleton<_i215.SignalingBridge>(
      () => _i215.SignalingBridge(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i787.AuthRepository>(
      () => _i153.AuthRepositoryImpl(gh<_i25.AuthRemoteDataSource>()),
    );
    gh.factory<_i349.PrescriptionBloc>(
      () => _i349.PrescriptionBloc(gh<_i976.PrescriptionService>()),
    );
    gh.lazySingleton<_i995.ConnectionRepository>(
      () => _i995.ConnectionRepositoryImpl(gh<_i558.ConnectionAuditService>()),
    );
    gh.factory<_i806.ChatBloc>(() => _i806.ChatBloc(gh<_i718.ChatService>()));
    gh.factory<_i156.CallBloc>(
      () => _i156.CallBloc(gh<_i215.SignalingBridge>()),
    );
    gh.factory<_i206.PreConsultationBloc>(
      () => _i206.PreConsultationBloc(gh<_i995.ConnectionRepository>()),
    );
    return this;
  }
}

class _$FirebaseModule extends _i616.FirebaseModule {}
