import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/client/client_bloc.dart';
import '../bloc/client/client_event.dart';
import '../bloc/client/client_state.dart';

class ClientDetailPage extends StatefulWidget {
  final String clientId;
  final VoidCallback onBack;

  const ClientDetailPage({
    super.key,
    required this.clientId,
    required this.onBack,
  });

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  @override
  void initState() {
    super.initState();

    context.read<ClientBloc>().add(ClientDetailRequested(widget.clientId));
  }

  void _retry() {
    context.read<ClientBloc>().add(ClientDetailRequested(widget.clientId));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: BlocBuilder<ClientBloc, ClientState>(
        builder: (context, state) {
          final detail = state.detail;

          if (state.isLoadingDetail) {
            return const Center(child: CircularProgressIndicator());
          }

          if (detail == null || detail.client.id != widget.clientId) {
            if (state.detailError != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal memuat detail Client: '
                      '${state.detailError}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                    TextButton(
                      onPressed: widget.onBack,
                      child: const Text('Kembali ke Clients'),
                    ),
                  ],
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          }

          final client = detail.client;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Kembali',
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Client Detail',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Informasi Client',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              _DetailItem(label: 'Nama', value: client.name),
                              _DetailItem(
                                label: 'Kewarganegaraan',
                                value: client.nationalityCode,
                              ),
                              _DetailItem(
                                label: 'Jenis Identitas',
                                value: client.identityType.name.toUpperCase(),
                              ),
                              _DetailItem(
                                label: 'Nomor Identitas',
                                value: client.identityNumber,
                              ),
                              _DetailItem(
                                label: 'Tanggal Lahir',
                                value: client.birthDate == null
                                    ? '-'
                                    : client.birthDate!
                                          .toLocal()
                                          .toString()
                                          .split(' ')
                                          .first,
                              ),
                              _DetailItem(
                                label: 'Gender',
                                value: client.gender?.name ?? '-',
                              ),
                              _DetailItem(
                                label: 'Telepon',
                                value: client.phone ?? '-',
                              ),
                              _DetailItem(
                                label: 'Email',
                                value: client.email ?? '-',
                              ),
                              _DetailItem(
                                label: 'Catatan',
                                value: client.notes ?? '-',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Alamat: ${detail.addresses.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Riwayat Perkara: ${detail.cases.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Riwayat Revisi: ${detail.revisions.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
