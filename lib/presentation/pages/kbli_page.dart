import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/kbli/kbli_bloc.dart';
import '../bloc/kbli/kbli_event.dart';
import '../bloc/kbli/kbli_state.dart';
import '../../../domain/entities/kbli.dart';
import '../../../domain/entities/kbli_conversion.dart';
import '../../../domain/entities/kbli_version.dart';

class KbliPage extends StatefulWidget {
  const KbliPage({super.key});

  @override
  State<KbliPage> createState() => _KbliPageState();
}

class _KbliPageState extends State<KbliPage> {
  final TextEditingController _searchController = TextEditingController();

  Kbli? _selectedKbli;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search({required KbliVersion version, required String query}) {
    context.read<KbliBloc>().add(
      KbliSearchRequested(version: version, query: query),
    );
  }

  void _changeVersion(KbliVersion version) {
    setState(() {
      _selectedKbli = null;
    });

    context.read<KbliBloc>().add(const KbliDetailCleared());

    _search(version: version, query: _searchController.text);
  }

  void _selectKbli(Kbli kbli) {
    setState(() {
      _selectedKbli = kbli;
    });

    context.read<KbliBloc>().add(const KbliDetailCleared());

    // Conversion data is sourced from the 2020 KBLI code.
    if (kbli.version == KbliVersion.kbli2020) {
      context.read<KbliBloc>().add(
        KbliConversionsRequested(sourceCode: kbli.code),
      );
    }
  }

  void _backToResults() {
    setState(() {
      _selectedKbli = null;
    });

    context.read<KbliBloc>().add(const KbliDetailCleared());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KbliBloc, KbliState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Klasifikasi Baku Lapangan Usaha Indonesia',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Cari kode dan uraian KBLI berdasarkan versi katalog.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              DropdownButton<KbliVersion>(
                value: state.version,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: KbliVersion.kbli2020,
                    child: Text('KBLI 2020'),
                  ),
                  DropdownMenuItem(
                    value: KbliVersion.kbli2025,
                    child: Text('KBLI 2025'),
                  ),
                ],
                onChanged: (version) {
                  if (version == null || version == state.version) {
                    return;
                  }

                  _changeVersion(version);
                },
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Cari kode atau uraian KBLI',
                  hintText: 'Contoh: 01111 atau pertanian jagung',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();

                            setState(() {
                              _selectedKbli = null;
                            });

                            context.read<KbliBloc>().add(
                              const KbliDetailCleared(),
                            );

                            _search(version: state.version, query: '');
                          },
                        ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (query) {
                  if (_selectedKbli != null) {
                    setState(() {
                      _selectedKbli = null;
                    });

                    context.read<KbliBloc>().add(const KbliDetailCleared());
                  }

                  _search(version: state.version, query: query);
                },
              ),
              const SizedBox(height: 16),

              if (state.error != null)
                _ErrorMessage(
                  message: state.error!,
                  onRetry: () {
                    _search(
                      version: state.version,
                      query: _searchController.text,
                    );
                  },
                ),

              if (_selectedKbli != null)
                Expanded(child: _buildDetail(context, state, _selectedKbli!))
              else
                Expanded(child: _buildResults(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResults(BuildContext context, KbliState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.query.trim().isEmpty) {
      return const Center(
        child: Text(
          'Masukkan kode atau uraian KBLI untuk memulai pencarian.',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (state.results.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ditemukan KBLI yang sesuai.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${state.results.length} hasil ditemukan',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: state.results.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final kbli = state.results[index];

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${kbli.code} — ${kbli.titleId}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  kbli.descriptionId?.isNotEmpty == true
                      ? kbli.descriptionId!
                      : 'Uraian tidak tersedia',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectKbli(kbli),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetail(BuildContext context, KbliState state, Kbli kbli) {
    return ListView(
      children: [
        TextButton.icon(
          onPressed: _backToResults,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Kembali ke hasil pencarian'),
        ),
        const SizedBox(height: 8),

        Text(kbli.code, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),

        Text(kbli.titleId, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),

        _DetailField(
          label: 'Versi',
          value: kbli.version == KbliVersion.kbli2020
              ? 'KBLI 2020'
              : 'KBLI 2025',
        ),
        _DetailField(
          label: 'Kategori',
          value: kbli.idKategori.isEmpty ? '-' : kbli.idKategori,
        ),
        _DetailField(
          label: 'ID versi',
          value: kbli.idVersion.isEmpty ? '-' : kbli.idVersion,
        ),
        _DetailField(
          label: 'Uraian',
          value: kbli.descriptionId?.isNotEmpty == true
              ? kbli.descriptionId!
              : 'Uraian tidak tersedia',
        ),

        if (kbli.titleEn.isNotEmpty)
          _DetailField(label: 'English title', value: kbli.titleEn),

        if (kbli.descriptionEn?.isNotEmpty == true)
          _DetailField(
            label: 'English description',
            value: kbli.descriptionEn!,
          ),

        if (kbli.tags?.isNotEmpty == true)
          _DetailField(label: 'Tags', value: kbli.tags!),

        const SizedBox(height: 20),

        if (kbli.version == KbliVersion.kbli2020)
          _buildConversions(context, state, kbli),
      ],
    );
  }

  Widget _buildConversions(BuildContext context, KbliState state, Kbli kbli) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Konversi ke KBLI 2025',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),

        if (state.isLoadingConversions)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.conversionsError != null)
          _ErrorMessage(
            message: state.conversionsError!,
            onRetry: () {
              context.read<KbliBloc>().add(
                KbliConversionsRequested(sourceCode: kbli.code),
              );
            },
          )
        else if (state.conversions.isEmpty)
          const Text('Tidak ada data konversi untuk kode ini.')
        else
          ...state.conversions.map(_buildConversionItem),
      ],
    );
  }

  Widget _buildConversionItem(KbliConversion conversion) {
    final targetCode = conversion.targetCode;

    return Card(
      child: ListTile(
        title: Text(
          targetCode == null || targetCode.isEmpty
              ? 'Tidak ditemukan kode tujuan'
              : targetCode,
        ),
        subtitle: Text(
          [
            if (conversion.relationType?.isNotEmpty == true)
              'Relasi: ${conversion.relationType}',
            if (conversion.relationNotation?.isNotEmpty == true)
              'Notasi: ${conversion.relationNotation}',
            'Status: ${conversion.status}',
          ].join('\n'),
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          SelectableText(value),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
