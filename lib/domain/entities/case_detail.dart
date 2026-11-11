import 'client.dart';
import 'document.dart';
import 'notary_case.dart';

/// Aggregated detail data for a notarial case.
///
/// Contains the main Case information, its related Client,
/// and all Documents associated with the Case.
class CaseDetail {
  final NotaryCase caseData;
  final Client client;
  final List<Document> documents;

  const CaseDetail({
    required this.caseData,
    required this.client,
    required this.documents,
  });
}
