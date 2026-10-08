import 'document.dart';
import 'notary_case.dart';

class ClientCaseDetail {
  final NotaryCase caseData;
  final List<Document> documents;

  const ClientCaseDetail({required this.caseData, required this.documents});
}
