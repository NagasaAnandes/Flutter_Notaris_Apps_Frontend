import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/case_detail.dart';
import '../../domain/entities/document.dart';
import '../../domain/enums/case_status.dart';
import '../../domain/enums/document_status.dart';
import '../../domain/enums/document_type.dart';
import '../bloc/case_detail/case_detail_bloc.dart';
import '../bloc/case_detail/case_detail_event.dart';
import '../bloc/case_detail/case_detail_state.dart';
import '../extensions/case_status_extension.dart';
import '../extensions/case_type_extension.dart';

class CaseDetailPage extends StatefulWidget {
  final String caseId;
  final VoidCallback? onBack;

  const CaseDetailPage({required this.caseId, this.onBack, super.key});

  @override
  State<CaseDetailPage> createState() => _CaseDetailPageState();
}

class _CaseDetailPageState extends State<CaseDetailPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<CaseDetailBloc>().add(
        CaseDetailRequested(caseId: widget.caseId),
      );
    });
  }

  void _loadDetail() {
    context.read<CaseDetailBloc>().add(
      CaseDetailRequested(caseId: widget.caseId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Kembali',
                onPressed:
                    widget.onBack ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Text(
                'Detail Case',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BlocBuilder<CaseDetailBloc, CaseDetailState>(
              builder: (context, state) {
                if (state is CaseDetailInitial || state is CaseDetailLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CaseDetailError) {
                  return _DetailErrorView(
                    message: state.message,
                    onRetry: _loadDetail,
                  );
                }

                if (state is CaseDetailLoaded) {
                  return _CaseDetailContent(detail: state.detail);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseDetailContent extends StatelessWidget {
  final CaseDetail detail;

  const _CaseDetailContent({required this.detail});

  @override
  Widget build(BuildContext context) {
    final caseData = detail.caseData;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CaseInformationCard(detail: detail),
              const SizedBox(height: 16),
              _ClientInformationCard(detail: detail),
              const SizedBox(height: 16),
              _CaseProgressCard(status: caseData.status),
              const SizedBox(height: 16),
              _RelatedDocumentsCard(documents: detail.documents),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaseInformationCard extends StatelessWidget {
  final CaseDetail detail;

  const _CaseInformationCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final caseData = detail.caseData;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informasi Case', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(caseData.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  avatar: const Icon(Icons.circle, size: 10),
                  label: Text(caseData.status.label),
                ),
                Chip(
                  avatar: const Icon(Icons.category_outlined, size: 16),
                  label: Text(caseData.type.label),
                ),
              ],
            ),
            const Divider(height: 28),
            _DetailRow(label: 'Case ID', value: caseData.id),
            _DetailRow(
              label: 'Tanggal Dibuat',
              value: _formatDateTime(caseData.createdAt),
            ),
            _DetailRow(
              label: 'Terakhir Diperbarui',
              value: _formatDateTime(caseData.updatedAt),
            ),
            _DetailRow(
              label: 'Tanggal Mulai',
              value: caseData.openedAt == null
                  ? '-'
                  : _formatDateTime(caseData.openedAt!),
            ),
            _DetailRow(
              label: 'Tanggal Selesai',
              value: caseData.closedAt == null
                  ? '-'
                  : _formatDateTime(caseData.closedAt!),
            ),
            if (caseData.description != null &&
                caseData.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Deskripsi', style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(caseData.description!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClientInformationCard extends StatelessWidget {
  final CaseDetail detail;

  const _ClientInformationCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final client = detail.client;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informasi Client', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    client.name.isEmpty
                        ? '?'
                        : client.name.substring(0, 1).toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(client.name, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const Divider(height: 28),
            _DetailRow(
              label: 'Jenis Identitas',
              value: client.identityType.name.toUpperCase(),
            ),
            _DetailRow(
              label: 'Nomor Identitas',
              value: _maskIdentityNumber(client.identityNumber),
            ),
            _DetailRow(label: 'Kewarganegaraan', value: client.nationalityCode),
            _DetailRow(label: 'Telepon', value: client.phone ?? '-'),
            _DetailRow(label: 'Email', value: client.email ?? '-'),
          ],
        ),
      ),
    );
  }
}

class _CaseProgressCard extends StatelessWidget {
  final CaseStatus status;

  const _CaseProgressCard({required this.status});

  static const _lifecycle = [
    CaseStatus.newCase,
    CaseStatus.draft,
    CaseStatus.dataComplete,
    CaseStatus.validated,
    CaseStatus.documentGenerated,
    CaseStatus.inReview,
    CaseStatus.approved,
    CaseStatus.finalized,
    CaseStatus.archived,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCancelled = status == CaseStatus.cancelled;
    final currentIndex = status == CaseStatus.revision
        ? _lifecycle.indexOf(CaseStatus.inReview)
        : _lifecycle.indexOf(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress Pengerjaan', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              isCancelled
                  ? 'Case dibatalkan.'
                  : 'Status saat ini: ${status.label}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (isCancelled)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.cancel_outlined, color: Colors.red),
                title: Text('Dibatalkan'),
                subtitle: Text('Case dihentikan sebelum tahap Final.'),
              )
            else
              ..._lifecycle.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isCurrent = item == status;
                final isCompleted = currentIndex >= 0 && index < currentIndex;

                return _LifecycleStep(
                  label: item.label,
                  isCurrent: isCurrent,
                  isCompleted: isCompleted,
                  isLast: index == _lifecycle.length - 1,
                );
              }),
            if (status == CaseStatus.revision) ...[
              const Divider(),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.edit_note),
                title: Text('Dalam tahap revisi'),
                subtitle: Text(
                  'Setelah revisi selesai, Case kembali ke pemeriksaan.',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LifecycleStep extends StatelessWidget {
  final String label;
  final bool isCurrent;
  final bool isCompleted;
  final bool isLast;

  const _LifecycleStep({
    required this.label,
    required this.isCurrent,
    required this.isCompleted,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCurrent || isCompleted
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : isCurrent
                      ? Icons.radio_button_checked
                      : Icons.circle_outlined,
                  size: 20,
                  color: color,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18, top: 1),
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isCurrent ? FontWeight.bold : null,
                  color: isCurrent
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (isCurrent)
            Chip(
              label: const Text('Saat ini'),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

class _RelatedDocumentsCard extends StatelessWidget {
  final List<Document> documents;

  const _RelatedDocumentsCard({required this.documents});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Related Documents',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Chip(label: Text('${documents.length} dokumen')),
              ],
            ),
            const SizedBox(height: 12),
            if (documents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.folder_open_outlined, size: 40),
                      SizedBox(height: 8),
                      Text('Belum ada dokumen untuk Case ini.'),
                    ],
                  ),
                ),
              )
            else
              ...documents.map((document) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.description_outlined),
                  ),
                  title: Text(document.title),
                  subtitle: Text(
                    '${_documentTypeLabel(document.type)} · '
                    '${_documentStatusLabel(document.status)}',
                  ),
                  trailing: Text(
                    _formatDateTime(document.updatedAt),
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _DetailErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          const Text('Gagal memuat detail Case'),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$day/$month/${date.year} $hour:$minute';
}

String _maskIdentityNumber(String value) {
  if (value.length <= 4) {
    return '••••';
  }

  return '${'•' * (value.length - 4)}${value.substring(value.length - 4)}';
}

String _documentTypeLabel(DocumentType type) {
  return switch (type) {
    DocumentType.akta => 'Akta',
    DocumentType.surat => 'Surat',
    DocumentType.lampiran => 'Lampiran',
    DocumentType.form => 'Formulir',
    DocumentType.supportingDocument => 'Dokumen Pendukung',
    DocumentType.other => 'Lainnya',
  };
}

String _documentStatusLabel(DocumentStatus status) {
  return switch (status) {
    DocumentStatus.draft => 'Draft',
    DocumentStatus.generated => 'Dibuat',
    DocumentStatus.review => 'Dalam Pemeriksaan',
    DocumentStatus.approved => 'Disetujui',
    DocumentStatus.finalized => 'Final',
    DocumentStatus.cancelled => 'Dibatalkan',
  };
}
