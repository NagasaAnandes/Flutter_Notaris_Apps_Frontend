import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/client.dart';
import '../../domain/entities/client_address.dart';
import '../../domain/enums/address_type.dart';
import '../../domain/enums/gender.dart';
import '../../domain/enums/identity_type.dart';
import '../bloc/client/client_bloc.dart';
import '../bloc/client/client_event.dart';
import '../bloc/client/client_state.dart';

class ClientCreateDialog extends StatefulWidget {
  const ClientCreateDialog({super.key});

  @override
  State<ClientCreateDialog> createState() => _ClientCreateDialogState();
}

class _ClientCreateDialogState extends State<ClientCreateDialog> {
  static const _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nationalityController = TextEditingController(text: 'ID');
  final _identityNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  IdentityType _identityType = IdentityType.nik;
  Gender? _gender;
  DateTime? _birthDate;

  final List<_AddressFormData> _addresses = [];

  @override
  void dispose() {
    _nameController.dispose();
    _nationalityController.dispose();
    _identityNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();

    for (final address in _addresses) {
      address.dispose();
    }

    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (selected != null && mounted) {
      setState(() => _birthDate = selected);
    }
  }

  void _addAddress() {
    setState(() => _addresses.add(_AddressFormData()));
  }

  void _removeAddress(int index) {
    final address = _addresses.removeAt(index);
    address.dispose();
    setState(() {});
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final clientId = _uuid.v4();

    final client = Client(
      id: clientId,
      name: _nameController.text.trim(),
      nationalityCode: _nationalityController.text.trim().toUpperCase(),
      identityType: _identityType,
      identityNumber: _identityNumberController.text.trim(),
      birthDate: _birthDate,
      gender: _gender,
      phone: _nullableText(_phoneController.text),
      email: _nullableText(_emailController.text),
      notes: _nullableText(_notesController.text),
      createdAt: now,
      updatedAt: now,
    );

    final addresses = _addresses.map((form) {
      return ClientAddress(
        id: _uuid.v4(),
        clientId: clientId,
        addressType: form.type,
        countryCode: form.countryCodeController.text.trim().toUpperCase(),
        postalCode: _nullableText(form.postalCodeController.text),
        addressDetail: form.detailController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    context.read<ClientBloc>().add(
      ClientCreateSubmitted(client: client, addresses: addresses),
    );
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
    return BlocListener<ClientBloc, ClientState>(
      listenWhen: (previous, current) =>
          previous.operationSuccess != current.operationSuccess ||
          previous.operationError != current.operationError,
      listener: (context, state) {
        debugPrint(
          'ClientCreateDialog listener: '
          'operationError=${state.operationError}, '
          'operationSuccess=${state.operationSuccess}',
        );

        if (state.operationError != null) {
          final errorMessage = state.operationError!;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            showDialog<void>(
              context: context,
              useRootNavigator: false,
              barrierDismissible: false,
              builder: (dialogContext) => AlertDialog(
                icon: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 36,
                ),
                title: const Text('Gagal Menyimpan Client'),
                content: Text(errorMessage),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Oke'),
                  ),
                ],
              ),
            );
          });
        }

        if (state.operationSuccess != null) {
          Navigator.of(context).pop(true);
        }
      },
      child: AlertDialog(
        title: const Text('Tambah Client'),
        content: SizedBox(
          width: 680,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nama *'),
                    validator: (value) => _requiredValidator(value, 'Nama'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nationalityController,
                    decoration: const InputDecoration(
                      labelText: 'Kode kewarganegaraan *',
                      hintText: 'ID',
                    ),
                    validator: (value) =>
                        _requiredValidator(value, 'Kewarganegaraan'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<IdentityType>(
                    initialValue: _identityType,
                    decoration: const InputDecoration(
                      labelText: 'Jenis identitas *',
                    ),
                    items: IdentityType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type == IdentityType.nik ? 'NIK' : 'Passport',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _identityType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _identityNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor identitas *',
                    ),
                    validator: (value) =>
                        _requiredValidator(value, 'Nomor identitas'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _selectBirthDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      _birthDate == null
                          ? 'Pilih tanggal lahir (opsional)'
                          : '${_birthDate!.day.toString().padLeft(2, '0')}/'
                                '${_birthDate!.month.toString().padLeft(2, '0')}/'
                                '${_birthDate!.year}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Gender?>(
                    initialValue: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender (opsional)',
                    ),
                    items: [
                      const DropdownMenuItem<Gender?>(
                        value: null,
                        child: Text('Tidak ditentukan'),
                      ),
                      ...Gender.values.map(
                        (gender) => DropdownMenuItem<Gender?>(
                          value: gender,
                          child: Text(switch (gender) {
                            Gender.male => 'Laki-laki',
                            Gender.female => 'Perempuan',
                            Gender.other => 'Lainnya',
                          }),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telepon (opsional)',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email (opsional)',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isNotEmpty &&
                          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)) {
                        return 'Format email tidak valid.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                    ),
                    maxLines: 3,
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Text(
                        'Alamat',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addAddress,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah alamat'),
                      ),
                    ],
                  ),
                  if (_addresses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Belum ada alamat.'),
                    ),
                  ..._addresses.asMap().entries.map((entry) {
                    final index = entry.key;
                    final address = entry.value;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text('Alamat ${index + 1}'),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Hapus alamat',
                                  onPressed: () => _removeAddress(index),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                            DropdownButtonFormField<AddressType>(
                              initialValue: address.type,
                              decoration: const InputDecoration(
                                labelText: 'Jenis alamat',
                              ),
                              items: AddressType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(_addressTypeLabel(type)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => address.type = value);
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: address.countryCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Kode negara *',
                                hintText: 'ID',
                              ),
                              validator: (value) =>
                                  _requiredValidator(value, 'Kode negara'),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: address.detailController,
                              decoration: const InputDecoration(
                                labelText: 'Detail alamat *',
                              ),
                              maxLines: 2,
                              validator: (value) =>
                                  _requiredValidator(value, 'Detail alamat'),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: address.postalCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Kode pos (opsional)',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        actions: [
          BlocBuilder<ClientBloc, ClientState>(
            builder: (context, state) {
              return TextButton(
                onPressed: state.isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              );
            },
          ),
          BlocBuilder<ClientBloc, ClientState>(
            builder: (context, state) {
              return FilledButton(
                onPressed: state.isSubmitting ? null : _submit,
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              );
            },
          ),
        ],
      ),
    );
  }

  String _addressTypeLabel(AddressType type) {
    return switch (type) {
      AddressType.identity => 'Identitas',
      AddressType.domicile => 'Domisili',
      AddressType.temporary => 'Sementara',
      AddressType.origin => 'Asal',
      AddressType.correspondence => 'Korespondensi',
      AddressType.other => 'Lainnya',
    };
  }
}

class _AddressFormData {
  AddressType type = AddressType.domicile;
  final countryCodeController = TextEditingController(text: 'ID');
  final detailController = TextEditingController();
  final postalCodeController = TextEditingController();

  void dispose() {
    countryCodeController.dispose();
    detailController.dispose();
    postalCodeController.dispose();
  }
}
