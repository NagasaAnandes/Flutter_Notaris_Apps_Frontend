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
import '../presentation/bloc/client/client_bloc.dart';
import '../domain/repositories/client_detail_repository.dart';
import '../domain/repositories/client_repository.dart';

class AppDependencies {
  AppDependencies(AppDatabase database) {
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

    final caseRepository = CaseRepositoryImpl(
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
  }

  late final ClientRepository clientRepository;
  late final ClientDetailRepository clientDetailRepository;
  late final ClientBloc clientBloc;
}
