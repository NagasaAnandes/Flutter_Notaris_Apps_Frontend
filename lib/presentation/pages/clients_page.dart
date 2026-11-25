import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/client/client_bloc.dart';
import '../bloc/client/client_event.dart';
import '../bloc/client/client_state.dart';
import '../../domain/entities/client.dart';

import 'client_create_dialog.dart';
import 'client_detail_page.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final TextEditingController _searchController = TextEditingController();

  String? _pendingEditClientId;
  String? _selectedDetailClientId;

  @override
  void initState() {
    super.initState();
    context.read<ClientBloc>().add(const ClientListRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<ClientBloc>().add(ClientSearchChanged(query: query));
  }

  void _onEditPressed(Client client) {
    final bloc = context.read<ClientBloc>();

    // Cegah permintaan detail bersamaan dari halaman ini.
    if (bloc.state.isLoadingDetail) return;

    _pendingEditClientId = client.id;

    bloc.add(ClientDetailRequested(client.id));
  }

  void _onViewPressed(Client client) {
    setState(() {
      _selectedDetailClientId = client.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientBloc, ClientState>(
      listenWhen: (previous, current) {
        return previous.isLoadingDetail && !current.isLoadingDetail;
      },
      listener: (context, state) {
        final pendingClientId = _pendingEditClientId;

        if (pendingClientId == null) return;

        final detail = state.detail;

        if (detail != null) {
          _pendingEditClientId = null;

          if (detail.client.id != pendingClientId) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Data Client yang dimuat tidak sesuai dengan pilihan.',
                ),
              ),
            );
            return;
          }

          showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => ClientCreateDialog(initialDetail: detail),
          );

          return;
        }

        if (state.detailError != null) {
          _pendingEditClientId = null;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat detail Client: ${state.detailError}'),
            ),
          );
        }
      },
      child: _selectedDetailClientId != null
          ? ClientDetailPage(
              clientId: _selectedDetailClientId!,
              onBack: () {
                setState(() {
                  _selectedDetailClientId = null;
                });
              },
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Clients',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () {
                          showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const ClientCreateDialog(),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Client'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 420,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        labelText: 'Cari Client',
                        hintText: 'Nama, nomor identitas, telepon, atau email',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus pencarian',
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                  setState(() {});
                                },
                              ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: BlocBuilder<ClientBloc, ClientState>(
                      builder: (context, state) {
                        if (state.isLoadingList && state.clients.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state.listError != null && state.clients.isEmpty) {
                          return _ErrorView(
                            message: state.listError!,
                            onRetry: () {
                              context.read<ClientBloc>().add(
                                const ClientListRequested(),
                              );
                            },
                          );
                        }

                        if (state.clients.isEmpty) {
                          return Center(
                            child: Text(
                              state.query.isEmpty
                                  ? 'Belum ada Client.'
                                  : 'Client tidak ditemukan.',
                            ),
                          );
                        }

                        return Column(
                          children: [
                            if (state.isLoadingList)
                              const LinearProgressIndicator(),
                            Expanded(
                              child: _ClientTable(
                                clients: state.clients,
                                isLoadingDetail: state.isLoadingDetail,
                                onEdit: _onEditPressed,
                                onView: _onViewPressed,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ClientTable extends StatelessWidget {
  final List<Client> clients;
  final bool isLoadingDetail;
  final ValueChanged<Client> onEdit;
  final ValueChanged<Client> onView;

  const _ClientTable({
    required this.clients,
    required this.isLoadingDetail,
    required this.onEdit,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Nama')),
            DataColumn(label: Text('Jenis Identitas')),
            DataColumn(label: Text('Nomor Identitas')),
            DataColumn(label: Text('Telepon')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: clients.map((client) {
            return DataRow(
              cells: [
                DataCell(Text(client.name)),
                DataCell(Text(client.identityType.name.toUpperCase())),
                DataCell(Text(client.identityNumber)),
                DataCell(Text(client.phone ?? '-')),
                DataCell(Text(client.email ?? '-')),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Lihat Detail',
                        onPressed: isLoadingDetail
                            ? null
                            : () => onView(client),
                        icon: const Icon(Icons.visibility_outlined),
                      ),
                      IconButton(
                        tooltip: 'Edit Client',
                        onPressed: isLoadingDetail
                            ? null
                            : () => onEdit(client),
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
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
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 12),
          Text('Gagal memuat Client: $message'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
