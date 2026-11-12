import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/case_id_generator.dart';
import '../../domain/entities/notary_case.dart';
import '../../domain/enums/case_status.dart';
import '../../domain/enums/case_type.dart';
import '../bloc/case/case_bloc.dart';
import '../bloc/case/case_event.dart';
import '../bloc/case/case_state.dart';
import 'client_create_dialog.dart';

class CaseCreateDialog extends StatefulWidget {
  const CaseCreateDialog({super.key});

  @override
  State<CaseCreateDialog> createState() => _CaseCreateDialogState();
}

class _CaseCreateDialogState extends State<CaseCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  static const _idGenerator = CaseIdGenerator();

  String? _selectedClientId;
  CaseType _selectedType = CaseType.incorporation;

  @override
  void initState() {
    super.initState();

    context.read<CaseBloc>().add(const CaseClientsRequested());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createClient() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ClientCreateDialog(),
    );

    if (!mounted || created != true) return;

    context.read<CaseBloc>().add(const CaseClientsRequested());
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClientId == null) return;

    final now = DateTime.now();

    final caseData = NotaryCase(
      id: _idGenerator.generate(),
      clientId: _selectedClientId!,
      type: _selectedType,
      status: CaseStatus.newCase,
      title: _titleController.text.trim(),
      description: _nullableText(_descriptionController.text),
      createdAt: now,
      updatedAt: now,
    );

    context.read<CaseBloc>().add(CaseCreateSubmitted(caseData: caseData));
  }

  String? _nullableText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String? _requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CaseBloc, CaseState>(
      listenWhen: (previous, current) =>
          previous.operationSuccess != current.operationSuccess,
      listener: (context, state) {
        if (state.operationSuccess != null) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        return AlertDialog(
          title: const Text('Buat Case Baru'),
          content: SizedBox(
            width: 560,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.operationError != null) ...[
                      _buildErrorMessage(context, state.operationError!),
                      const SizedBox(height: 16),
                    ],

                    const Text(
                      'Client',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    if (state.isLoadingClients)
                      const LinearProgressIndicator()
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _selectedClientId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Pilih Client',
                        ),
                        items: state.clients.map((client) {
                          return DropdownMenuItem<String>(
                            value: client.id,
                            child: Text(
                              '${client.name} - ${client.identityNumber}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: state.isSubmitting
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedClientId = value;
                                });
                              },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Client wajib dipilih.';
                          }
                          return null;
                        },
                      ),

                    if (state.clientsError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.clientsError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          context.read<CaseBloc>().add(
                            const CaseClientsRequested(),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Muat ulang Client'),
                      ),
                    ],

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: state.isSubmitting ? null : _createClient,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Tambah Client baru'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Jenis Akta',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<CaseType>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: CaseType.incorporation,
                          child: Text('Pendirian PT'),
                        ),
                      ],
                      onChanged: state.isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedType = value;
                                });
                              }
                            },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _titleController,
                      enabled: !state.isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Judul Case *',
                        hintText: 'Contoh: Pendirian PT Maju Bersama',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          _requiredValidator(value, 'Judul Case'),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      enabled: !state.isSubmitting,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        hintText: 'Keterangan tambahan (opsional)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi otomatis',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 8),
                          Text('Case ID: dibuat otomatis saat disimpan'),
                          Text('Initial Status: NEW'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: state.isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              onPressed: state.isSubmitting || state.isLoadingClients
                  ? null
                  : _submit,
              icon: state.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(state.isSubmitting ? 'Menyimpan...' : 'Buat Case'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorMessage(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: const Key('case-create-error-container'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              key: const Key('case-create-operation-error'),
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
