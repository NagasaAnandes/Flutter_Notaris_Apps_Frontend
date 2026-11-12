import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/case_list_item.dart';
import '../../domain/filters/case_list_query.dart';
import '../../domain/enums/case_status.dart';
import '../../domain/enums/case_type.dart';
import '../extensions/case_status_extension.dart';
import '../extensions/case_type_extension.dart';
import '../bloc/case/case_bloc.dart';
import '../bloc/case/case_event.dart';
import '../bloc/case/case_state.dart';
import 'case_create_dialog.dart';
import 'case_detail_page.dart';

enum _CaseSortOption {
  recentlyUpdated,
  recentlyCreated,
  titleAscending,
  titleDescending,
}

class CasesPage extends StatefulWidget {
  const CasesPage({super.key});

  @override
  State<CasesPage> createState() => _CasesPageState();
}

class _CasesPageState extends State<CasesPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCaseId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<CaseBloc>().add(const CaseListRequested());
    });
  }

  void _openCaseDetail(String caseId) {
    setState(() {
      _selectedCaseId = caseId;
    });
  }

  void _closeCaseDetail() {
    setState(() {
      _selectedCaseId = null;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CaseCreateDialog(),
    );

    if (!mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Case berhasil dibuat.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onSearchChanged(String value) {
    final bloc = context.read<CaseBloc>();
    final currentQuery = bloc.state.caseListQuery;

    bloc.add(
      CaseListRequested(query: currentQuery.copyWith(searchQuery: value)),
    );
  }

  Future<void> _refreshCases() async {
    final bloc = context.read<CaseBloc>();

    // Tunggu sampai proses refresh benar-benar dimulai.
    final loadingStarted = bloc.stream.firstWhere(
      (state) => state.isLoadingCases,
    );

    bloc.add(CaseListRequested(query: bloc.state.caseListQuery));

    await loadingStarted;

    // Tunggu sampai proses refresh selesai.
    await bloc.stream.firstWhere((state) => !state.isLoadingCases);
  }

  _CaseSortOption _getSortOption(CaseListQuery query) {
    if (query.sortBy == CaseListSortField.createdAt) {
      return _CaseSortOption.recentlyCreated;
    }

    if (query.sortBy == CaseListSortField.title) {
      return query.sortDirection == SortDirection.ascending
          ? _CaseSortOption.titleAscending
          : _CaseSortOption.titleDescending;
    }

    return _CaseSortOption.recentlyUpdated;
  }

  void _onSortChanged(_CaseSortOption? option) {
    if (option == null) return;

    final bloc = context.read<CaseBloc>();
    final query = bloc.state.caseListQuery;

    final CaseListSortField sortBy;
    final SortDirection direction;

    switch (option) {
      case _CaseSortOption.recentlyUpdated:
        sortBy = CaseListSortField.updatedAt;
        direction = SortDirection.descending;
        break;

      case _CaseSortOption.recentlyCreated:
        sortBy = CaseListSortField.createdAt;
        direction = SortDirection.descending;
        break;

      case _CaseSortOption.titleAscending:
        sortBy = CaseListSortField.title;
        direction = SortDirection.ascending;
        break;

      case _CaseSortOption.titleDescending:
        sortBy = CaseListSortField.title;
        direction = SortDirection.descending;
        break;
    }

    bloc.add(
      CaseListRequested(
        query: query.copyWith(sortBy: sortBy, sortDirection: direction),
      ),
    );
  }

  Future<void> _showStatusFilter() async {
    final bloc = context.read<CaseBloc>();
    final currentStatuses = List<CaseStatus>.from(
      bloc.state.caseListQuery.statuses,
    );

    final selectedStatuses = await showDialog<List<CaseStatus>>(
      context: context,
      builder: (dialogContext) {
        final selected = List<CaseStatus>.from(currentStatuses);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Status'),
              content: SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: CaseStatus.values.map((status) {
                      return CheckboxListTile(
                        value: selected.contains(status),
                        title: Text(status.label),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              selected.add(status);
                            } else {
                              selected.remove(status);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, <CaseStatus>[]);
                  },
                  child: const Text('Reset'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      List<CaseStatus>.from(selected),
                    );
                  },
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || selectedStatuses == null) return;

    final query = bloc.state.caseListQuery.copyWith(statuses: selectedStatuses);

    bloc.add(CaseListRequested(query: query));
  }

  Future<void> _showTypeFilter() async {
    final bloc = context.read<CaseBloc>();
    final currentTypes = List<CaseType>.from(bloc.state.caseListQuery.types);

    final selectedTypes = await showDialog<List<CaseType>>(
      context: context,
      builder: (dialogContext) {
        final selected = List<CaseType>.from(currentTypes);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Jenis Case'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: CaseType.values.map((type) {
                    return CheckboxListTile(
                      value: selected.contains(type),
                      title: Text(type.label),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true) {
                            selected.add(type);
                          } else {
                            selected.remove(type);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, <CaseType>[]);
                  },
                  child: const Text('Reset'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, List<CaseType>.from(selected));
                  },
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || selectedTypes == null) return;

    final query = bloc.state.caseListQuery.copyWith(types: selectedTypes);

    bloc.add(CaseListRequested(query: query));
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCaseId != null) {
      return CaseDetailPage(caseId: _selectedCaseId!, onBack: _closeCaseDetail);
    }

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manajemen Case',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kelola seluruh pekerjaan notarial.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Refresh daftar Case',
                    onPressed: _refreshCases,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const Key('create-case-button'),
                    onPressed: _openCreateDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Case Baru'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 420,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                return TextField(
                  key: const Key('case-search-field'),
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari Case atau nama Client...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            icon: const Icon(Icons.close),
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                );
              },
            ),
          ),

          BlocBuilder<CaseBloc, CaseState>(
            builder: (context, state) {
              final query = state.caseListQuery;

              return Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _showStatusFilter,
                    icon: const Icon(Icons.filter_list),
                    label: Text(
                      query.statuses.isEmpty
                          ? 'Status'
                          : 'Status (${query.statuses.length})',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showTypeFilter,
                    icon: const Icon(Icons.category_outlined),
                    label: Text(
                      query.types.isEmpty
                          ? 'Jenis Case'
                          : 'Jenis (${query.types.length})',
                    ),
                  ),

                  // SORTING CASE
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 230),
                    child: DropdownButtonFormField<_CaseSortOption>(
                      key: const Key('case-sort-dropdown'),
                      initialValue: _getSortOption(query),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Urutkan',
                        prefixIcon: Icon(Icons.sort),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      selectedItemBuilder: (context) {
                        return const [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Terakhir Diperbarui',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Tanggal Dibuat',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Judul A–Z',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Judul Z–A',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ];
                      },
                      items: const [
                        DropdownMenuItem(
                          value: _CaseSortOption.recentlyUpdated,
                          child: Text('Terakhir Diperbarui'),
                        ),
                        DropdownMenuItem(
                          value: _CaseSortOption.recentlyCreated,
                          child: Text('Tanggal Dibuat'),
                        ),
                        DropdownMenuItem(
                          value: _CaseSortOption.titleAscending,
                          child: Text('Judul A–Z'),
                        ),
                        DropdownMenuItem(
                          value: _CaseSortOption.titleDescending,
                          child: Text('Judul Z–A'),
                        ),
                      ],
                      onChanged: _onSortChanged,
                    ),
                  ),

                  if (query.statuses.isNotEmpty || query.types.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        context.read<CaseBloc>().add(
                          CaseListRequested(
                            query: query.copyWith(
                              statuses: const [],
                              types: const [],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Reset Filter'),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),
          Expanded(
            child: BlocBuilder<CaseBloc, CaseState>(
              builder: (context, state) {
                if (state.isLoadingCases && state.cases.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.casesError != null && state.cases.isEmpty) {
                  return _ErrorView(
                    message: state.casesError!,
                    onRetry: () {
                      context.read<CaseBloc>().add(
                        CaseListRequested(query: state.caseListQuery),
                      );
                    },
                  );
                }

                if (state.cases.isEmpty) {
                  return _EmptyView(
                    onCreate: _openCreateDialog,
                    isSearching: state.caseListQuery.searchQuery.isNotEmpty,
                  );
                }

                return Column(
                  children: [
                    if (state.casesError != null)
                      MaterialBanner(
                        content: Text(state.casesError!),
                        actions: [
                          TextButton(
                            onPressed: () {
                              context.read<CaseBloc>().add(
                                CaseListRequested(query: state.caseListQuery),
                              );
                            },
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshCases,
                        child: ListView.separated(
                          key: const Key('case-list'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: state.cases.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return _CaseListTile(
                              item: state.cases[index],
                              onTap: () =>
                                  _openCaseDetail(state.cases[index].id),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseListTile extends StatelessWidget {
  final CaseListItem item;
  final VoidCallback onTap;

  const _CaseListTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.folder_outlined,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(item.title, style: theme.textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _Metadata(icon: Icons.person_outline, text: item.clientName),
              _Metadata(icon: Icons.category_outlined, text: item.type.label),
              _Metadata(icon: Icons.update, text: _formatDate(item.updatedAt)),
              Tooltip(
                message: 'Case ID: ${item.id}',
                child: _Metadata(icon: Icons.tag, text: _formatCaseId(item.id)),
              ),
            ],
          ),
        ),
        trailing: Chip(label: Text(item.status.label)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatCaseId(String id) {
    final normalized = id.replaceAll('-', '').toUpperCase();

    final shortId = normalized.length > 8
        ? normalized.substring(0, 8)
        : normalized;

    return 'CASE-$shortId';
  }
}

class _Metadata extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Metadata({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 5),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onCreate;
  final bool isSearching;

  const _EmptyView({required this.onCreate, required this.isSearching});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.folder_open_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Case tidak ditemukan' : 'Belum ada Case',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Coba gunakan kata kunci pencarian lain.'
                : 'Buat Case baru untuk memulai pekerjaan notarial.',
            textAlign: TextAlign.center,
          ),
          if (!isSearching) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Buat Case Baru'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Gagal memuat daftar Case'),
          const SizedBox(height: 8),
          Text(message),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
