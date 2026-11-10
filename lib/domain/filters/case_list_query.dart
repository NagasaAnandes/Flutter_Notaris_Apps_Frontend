import '../enums/case_status.dart';
import '../enums/case_type.dart';

enum CaseListSortField { updatedAt, createdAt, title }

enum SortDirection { ascending, descending }

class CaseListQuery {
  final String searchQuery;
  final List<CaseStatus> statuses;
  final List<CaseType> types;
  final CaseListSortField sortBy;
  final SortDirection sortDirection;

  const CaseListQuery({
    this.searchQuery = '',
    this.statuses = const [],
    this.types = const [],
    this.sortBy = CaseListSortField.updatedAt,
    this.sortDirection = SortDirection.descending,
  });

  CaseListQuery copyWith({
    String? searchQuery,
    List<CaseStatus>? statuses,
    List<CaseType>? types,
    CaseListSortField? sortBy,
    SortDirection? sortDirection,
  }) {
    return CaseListQuery(
      searchQuery: searchQuery ?? this.searchQuery,
      statuses: statuses ?? this.statuses,
      types: types ?? this.types,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }
}
