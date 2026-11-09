import '../core/database/database.dart';
import '../data/datasources/local/audit_log_local_datasource_impl.dart';
import '../data/datasources/local/case_kbli_local_datasource_impl.dart';
import '../data/datasources/local/case_local_datasource_impl.dart';
import '../data/datasources/local/case_party_local_datasource_impl.dart';
import '../data/datasources/local/client_local_datasource_impl.dart';
import '../data/datasources/local/client_revision_local_datasource_impl.dart';
import '../data/datasources/local/document_local_datasource_impl.dart';
import '../data/datasources/local/document_revision_local_datasource_impl.dart';
import '../data/repositories/case_repository_impl.dart';
import '../data/repositories/client_detail_repository_impl.dart';
import '../data/repositories/client_repository_impl.dart';
import '../data/repositories/document_repository_impl.dart';
import '../domain/repositories/case_repository.dart';
import '../domain/repositories/client_detail_repository.dart';
import '../domain/repositories/client_repository.dart';
import '../presentation/bloc/case/case_bloc.dart';
import '../presentation/bloc/client/client_bloc.dart';

class AppDependencies {
  AppDependencies(AppDatabase database) : _database = database {
    final clientDataSource = ClientLocalDataSourceImpl(database);
    final clientRevisionDataSource = ClientRevisionLocalDataSourceImpl(
      database,
    );
    final auditLogDataSource = AuditLogLocalDataSourceImpl(database);

    final caseDataSource = CaseLocalDataSourceImpl(database);
    final casePartyDataSource = CasePartyLocalDataSourceImpl(database);
    final caseKbliDataSource = CaseKbliLocalDataSourceImpl(database);

    final documentDataSource = DocumentLocalDataSourceImpl(database);
    final documentRevisionDataSource = DocumentRevisionLocalDataSourceImpl(
      database,
    );

    clientRepository = ClientRepositoryImpl(
      database,
      clientDataSource,
      clientRevisionDataSource,
      auditLogDataSource,
    );

    caseRepository = CaseRepositoryImpl(
      caseDataSource,
      casePartyDataSource,
      caseKbliDataSource,
    );

    final documentRepository = DocumentRepositoryImpl(
      documentDataSource,
      documentRevisionDataSource,
    );

    clientDetailRepository = ClientDetailRepositoryImpl(
      clientRepository,
      caseRepository,
      documentRepository,
    );

    clientBloc = ClientBloc(clientRepository, clientDetailRepository);

    caseBloc = CaseBloc(caseRepository, clientRepository);
  }

  final AppDatabase _database;

  late final ClientRepository clientRepository;
  late final CaseRepository caseRepository;
  late final ClientDetailRepository clientDetailRepository;

  late final ClientBloc clientBloc;
  late final CaseBloc caseBloc;

  Future<void>? _disposeFuture;

  /// Closes application resources exactly once.
  Future<void> dispose() {
    return _disposeFuture ??= _disposeResources();
  }

  Future<void> _disposeResources() async {
    // Close BLoCs before closing the database they depend on.
    await caseBloc.close();
    await clientBloc.close();

    await _database.close();
  }
}
