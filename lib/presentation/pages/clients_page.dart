import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/client/client_bloc.dart';
import '../bloc/client/client_event.dart';
import '../bloc/client/client_state.dart';
import '../../domain/entities/client.dart';

import 'client_create_dialog.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final TextEditingController _searchController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  return const Center(child: CircularProgressIndicator());
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
                    if (state.isLoadingList) const LinearProgressIndicator(),
                    Expanded(child: _ClientTable(clients: state.clients)),
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

class _ClientTable extends StatelessWidget {
  final List<Client> clients;

  const _ClientTable({required this.clients});

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
          ],
          rows: clients.map((client) {
            return DataRow(
              cells: [
                DataCell(Text(client.name)),
                DataCell(Text(client.identityType.name.toUpperCase())),
                DataCell(Text(client.identityNumber)),
                DataCell(Text(client.phone ?? '-')),
                DataCell(Text(client.email ?? '-')),
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
