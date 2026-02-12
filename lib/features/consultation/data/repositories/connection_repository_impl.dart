import 'package:injectable/injectable.dart';
import 'package:mediconnect/features/consultation/data/data_sources/connection_audit_service.dart';
import 'package:mediconnect/features/consultation/domain/entities/connection_status.dart';

abstract class ConnectionRepository {
  Future<ConnectionStatus> checkConnection();
}

@LazySingleton(as: ConnectionRepository)
class ConnectionRepositoryImpl implements ConnectionRepository {
  final ConnectionAuditService _connectionAuditService;

  ConnectionRepositoryImpl(this._connectionAuditService);

  @override
  Future<ConnectionStatus> checkConnection() {
    return _connectionAuditService.checkConnection();
  }
}
