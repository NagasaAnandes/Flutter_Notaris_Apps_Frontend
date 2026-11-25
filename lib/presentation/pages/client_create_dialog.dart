import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../app/app_dependencies.dart';
import '../../data/datasources/local/region_local_datasource.dart';
import '../../data/importers/regions/region_dataset_manager.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/client_address.dart';
import '../../domain/entities/client_detail.dart';
import '../../domain/entities/administrative_region.dart';
import '../../domain/enums/address_type.dart';
import '../../domain/enums/gender.dart';
import '../../domain/enums/identity_type.dart';
import '../bloc/client/client_bloc.dart';
import '../bloc/client/client_event.dart';
import '../bloc/client/client_state.dart';

class ClientCreateDialog extends StatefulWidget {
  final ClientDetail? initialDetail;

  // Optional overrides untuk pengujian.
  final RegionDatasetManager? regionDatasetManager;
  final RegionLocalDataSource? regionLocalDataSource;

  const ClientCreateDialog({
    super.key,
    this.initialDetail,
    this.regionDatasetManager,
    this.regionLocalDataSource,
  });

  bool get isEditing => initialDetail != null;

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

  RegionDatasetManager get _regionDatasetManager =>
      widget.regionDatasetManager ??
      context.read<AppDependencies>().regionDatasetManager;

  RegionLocalDataSource get _regionLocalDataSource =>
      widget.regionLocalDataSource ??
      context.read<AppDependencies>().regionLocalDataSource;

  bool _regionFormsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_regionFormsInitialized) return;
    _regionFormsInitialized = true;

    for (final address in _addresses) {
      unawaited(_initializeRegionForm(address));
    }
  }

  @override
  void initState() {
    super.initState();

    final detail = widget.initialDetail;
    if (detail == null) return;

    final client = detail.client;

    _nameController.text = client.name;
    _nationalityController.text = client.nationalityCode;
    _identityNumberController.text = client.identityNumber;
    _phoneController.text = client.phone ?? '';
    _emailController.text = client.email ?? '';
    _notesController.text = client.notes ?? '';

    _identityType = client.identityType;
    _gender = client.gender;
    _birthDate = client.birthDate;

    _addresses.addAll(detail.addresses.map(_AddressFormData.fromAddress));
  }

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

  Future<void> _initializeRegionForm(_AddressFormData form) async {
    if (form.countryCodeController.text.trim().toUpperCase() != 'ID') {
      return;
    }

    if (!mounted || !_addresses.contains(form)) return;

    // Setiap inisialisasi baru membatalkan request sebelumnya.
    final requestVersion = ++form.regionRequestVersion;

    bool isCurrentRequest() {
      return mounted &&
          _addresses.contains(form) &&
          requestVersion == form.regionRequestVersion;
    }

    form.isRegionLoading = true;
    form.regionError = null;

    setState(() {});

    try {
      final original = form.original;
      final originalDatasetId = original?.regionDatasetId;

      // Alamat lama memiliki kode wilayah tetapi tidak memiliki dataset.
      if (original != null &&
          originalDatasetId == null &&
          (original.provinceId != null ||
              original.regencyId != null ||
              original.districtId != null ||
              original.villageId != null)) {
        form.isLegacyRegion = true;
        form.regionError =
            'Alamat lama tidak memiliki referensi dataset wilayah. '
            'Data historis tetap dipertahankan.';
        return;
      }

      Map<String, Object?>? dataset;

      if (originalDatasetId != null && originalDatasetId.isNotEmpty) {
        dataset = await _regionDatasetManager.getDatasetById(originalDatasetId);

        if (!isCurrentRequest()) return;

        if (dataset == null || dataset['status'] != 'ACTIVE') {
          form.isLegacyRegion = true;
          form.regionDatasetId = originalDatasetId;
          return;
        }
      } else {
        dataset = await _regionDatasetManager.getActiveDataset();

        if (!isCurrentRequest()) return;

        if (dataset == null) {
          form.regionError = 'Belum ada dataset wilayah aktif.';
          return;
        }
      }

      if (!isCurrentRequest()) return;

      final datasetId = dataset['id'] as String;
      form.regionDatasetId = datasetId;

      final provinces = await _regionLocalDataSource.getProvinces(
        datasetId: datasetId,
      );

      if (!isCurrentRequest()) return;

      form.provinces = provinces;

      final provinceCode = form.provinceCode;
      if (provinceCode == null) return;

      if (!form.provinces.any((e) => e.code == provinceCode)) {
        form.isLegacyRegion = true;
        form.regionError = 'Provinsi lama tidak ditemukan dalam dataset.';
        return;
      }

      final regencies = await _regionLocalDataSource.getRegencies(
        datasetId: datasetId,
        provinceCode: provinceCode,
      );

      if (!isCurrentRequest()) return;

      form.regencies = regencies;

      final regencyCode = form.regencyCode;
      if (regencyCode == null) return;

      if (!form.regencies.any((e) => e.code == regencyCode)) {
        form.isLegacyRegion = true;
        form.regionError = 'Kabupaten/kota lama tidak sesuai dengan provinsi.';
        return;
      }

      final districts = await _regionLocalDataSource.getDistricts(
        datasetId: datasetId,
        regencyCode: regencyCode,
      );

      if (!isCurrentRequest()) return;

      form.districts = districts;

      final districtCode = form.districtCode;
      if (districtCode == null) return;

      if (!form.districts.any((e) => e.code == districtCode)) {
        form.isLegacyRegion = true;
        form.regionError = 'Kecamatan lama tidak sesuai dengan kabupaten/kota.';
        return;
      }

      final villages = await _regionLocalDataSource.getVillages(
        datasetId: datasetId,
        districtCode: districtCode,
      );

      if (!isCurrentRequest()) return;

      form.villages = villages;

      final villageCode = form.villageCode;

      if (villageCode != null &&
          !form.villages.any((e) => e.code == villageCode)) {
        form.isLegacyRegion = true;
        form.regionError = 'Desa/kelurahan lama tidak sesuai dengan kecamatan.';
      }
    } catch (error) {
      if (!isCurrentRequest()) return;

      form.regionError = 'Gagal memuat data wilayah: $error';
    } finally {
      // Request yang sudah dibatalkan tidak boleh mengubah loading
      // milik request yang lebih baru.
      if (isCurrentRequest()) {
        form.isRegionLoading = false;
        setState(() {});
      }
    }
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
    final address = _AddressFormData();

    setState(() => _addresses.add(address));

    unawaited(_initializeRegionForm(address));
  }

  void _removeAddress(int index) {
    final address = _addresses.removeAt(index);
    address.dispose();
    setState(() {});
  }

  void _handleCountryCodeChanged(_AddressFormData address, String value) {
    final isIndonesia = value.trim().toUpperCase() == 'ID';

    if (!isIndonesia) {
      setState(() {
        // Batalkan request wilayah yang masih berjalan.
        address.regionRequestVersion++;
        address.isRegionLoading = false;

        // Jangan hapus kode maupun daftar wilayah.
        // Referensi tetap disimpan dalam state form agar dapat
        // dipulihkan jika negara dikembalikan menjadi Indonesia.
        address.regionError = null;
      });
      return;
    }

    setState(() {});

    // Muat ulang hierarki wilayah untuk memastikan daftar dropdown
    // tetap sinkron dengan kode wilayah yang dipertahankan.
    if (!address.isLegacyRegion) {
      unawaited(_initializeRegionForm(address));
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final existingClient = widget.initialDetail?.client;
    final clientId = existingClient?.id ?? _uuid.v4();

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
      createdAt: existingClient?.createdAt ?? now,
      updatedAt: now,
    );

    final addresses = _addresses.map((form) {
      final existingAddress = form.original;
      final countryCode = form.countryCodeController.text.trim().toUpperCase();

      final isIndonesia = countryCode == 'ID';

      // Dataset RETIRED atau referensi lama yang tidak dapat
      // diverifikasi harus dipertahankan sampai dipilih ulang.
      final preserveLegacyRegion =
          isIndonesia && form.isLegacyRegion && existingAddress != null;

      final regionDatasetId = !isIndonesia
          ? null
          : preserveLegacyRegion
          ? existingAddress.regionDatasetId
          : form.regionDatasetId;

      final provinceId = !isIndonesia
          ? null
          : preserveLegacyRegion
          ? existingAddress.provinceId
          : form.provinceCode;

      final regencyId = !isIndonesia
          ? null
          : preserveLegacyRegion
          ? existingAddress.regencyId
          : form.regencyCode;

      final districtId = !isIndonesia
          ? null
          : preserveLegacyRegion
          ? existingAddress.districtId
          : form.districtCode;

      final villageId = !isIndonesia
          ? null
          : preserveLegacyRegion
          ? existingAddress.villageId
          : form.villageCode;

      return ClientAddress(
        id: existingAddress?.id ?? _uuid.v4(),
        clientId: clientId,
        addressType: form.type,
        countryCode: countryCode,

        // Use current form selections, except legacy references
        // that must remain unchanged until explicit reselection.
        regionDatasetId: regionDatasetId,
        provinceId: provinceId,
        regencyId: regencyId,
        districtId: districtId,
        villageId: villageId,

        // Preserve neighborhood information.
        rt: existingAddress?.rt,
        rw: existingAddress?.rw,

        // Preserve foreign address information.
        foreignState: existingAddress?.foreignState,
        foreignCity: existingAddress?.foreignCity,

        postalCode: _nullableText(form.postalCodeController.text),
        addressDetail: form.detailController.text.trim(),
        createdAt: existingAddress?.createdAt ?? now,
        updatedAt: now,
      );
    }).toList();

    final bloc = context.read<ClientBloc>();

    if (existingClient == null) {
      bloc.add(ClientCreateSubmitted(client: client, addresses: addresses));
    } else {
      bloc.add(ClientUpdateSubmitted(client: client, addresses: addresses));
    }
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
          previous.operationSuccess != current.operationSuccess,
      listener: (context, state) {
        if (state.operationSuccess != null) {
          Navigator.of(context).pop(true);
        }
      },
      child: BlocBuilder<ClientBloc, ClientState>(
        builder: (context, state) {
          return AlertDialog(
            title: Text(widget.isEditing ? 'Edit Client' : 'Tambah Client'),
            content: SizedBox(
              width: 680,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.operationError != null) ...[
                        Container(
                          key: const Key('client-create-error-container'),
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.operationError!,
                                  key: const Key(
                                    'client-create-operation-error',
                                  ),
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

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
                        onChanged: (value) {
                          setState(() => _gender = value);
                        },
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
                            onPressed: state.isSubmitting ? null : _addAddress,
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
                                      onPressed: state.isSubmitting
                                          ? null
                                          : () => _removeAddress(index),
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
                                  onChanged: state.isSubmitting
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            setState(() {
                                              address.type = value;
                                            });
                                          }
                                        },
                                ),
                                const SizedBox(height: 8),

                                TextFormField(
                                  controller: address.countryCodeController,
                                  enabled: !state.isSubmitting,
                                  decoration: const InputDecoration(
                                    labelText: 'Kode negara *',
                                    hintText: 'ID',
                                  ),
                                  onChanged: (value) =>
                                      _handleCountryCodeChanged(address, value),
                                  validator: (value) =>
                                      _requiredValidator(value, 'Kode negara'),
                                ),

                                if (address.countryCodeController.text
                                        .trim()
                                        .toUpperCase() ==
                                    'ID')
                                  _buildRegionStatus(address),
                                const SizedBox(height: 12),
                                _buildProvinceDropdown(address),
                                const SizedBox(height: 8),

                                _buildRegencyDropdown(address),
                                const SizedBox(height: 8),

                                _buildDistrictDropdown(address),
                                const SizedBox(height: 8),

                                _buildVillageDropdown(address),
                                const SizedBox(height: 8),

                                TextFormField(
                                  controller: address.detailController,
                                  enabled: !state.isSubmitting,
                                  decoration: const InputDecoration(
                                    labelText: 'Detail alamat *',
                                  ),
                                  maxLines: 2,
                                  validator: (value) => _requiredValidator(
                                    value,
                                    'Detail alamat',
                                  ),
                                ),
                                const SizedBox(height: 8),

                                TextFormField(
                                  controller: address.postalCodeController,
                                  enabled: !state.isSubmitting,
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
              TextButton(
                onPressed: state.isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: state.isSubmitting ? null : _submit,
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectProvince(
    _AddressFormData address,
    String? provinceCode,
  ) async {
    if (address.isLegacyRegion) return;

    final requestVersion = ++address.regionRequestVersion;

    setState(() {
      address.provinceCode = provinceCode;
      address.regencyCode = null;
      address.districtCode = null;
      address.villageCode = null;

      address.regencies = [];
      address.districts = [];
      address.villages = [];

      address.regionError = null;
      address.isRegionLoading = provinceCode != null;
    });

    if (provinceCode == null) return;

    final datasetId = address.regionDatasetId;
    if (datasetId == null) {
      if (mounted && _addresses.contains(address)) {
        setState(() {
          address.isRegionLoading = false;
          address.regionError = 'Dataset wilayah tidak tersedia.';
        });
      }
      return;
    }

    try {
      final regencies = await _regionLocalDataSource.getRegencies(
        datasetId: datasetId,
        provinceCode: provinceCode,
      );

      if (!mounted ||
          !_addresses.contains(address) ||
          requestVersion != address.regionRequestVersion) {
        return;
      }

      setState(() {
        address.regencies = regencies;
      });
    } catch (error) {
      if (!mounted ||
          !_addresses.contains(address) ||
          requestVersion != address.regionRequestVersion) {
        return;
      }

      setState(() {
        address.regionError = 'Gagal memuat kabupaten/kota: $error';
      });
    } finally {
      if (mounted &&
          _addresses.contains(address) &&
          requestVersion == address.regionRequestVersion) {
        setState(() {
          address.isRegionLoading = false;
        });
      }
    }
  }

  Future<void> _selectRegency(
    _AddressFormData address,
    String? regencyCode,
  ) async {
    if (address.isLegacyRegion) return;

    final requestVersion = ++address.regionRequestVersion;

    setState(() {
      address.regencyCode = regencyCode;
      address.districtCode = null;
      address.villageCode = null;

      address.districts = [];
      address.villages = [];

      address.regionError = null;
      address.isRegionLoading = regencyCode != null;
    });

    if (regencyCode == null) return;

    final datasetId = address.regionDatasetId;
    if (datasetId == null) {
      if (mounted && _addresses.contains(address)) {
        setState(() {
          address.isRegionLoading = false;
          address.regionError = 'Dataset wilayah tidak tersedia.';
        });
      }
      return;
    }

    try {
      final districts = await _regionLocalDataSource.getDistricts(
        datasetId: datasetId,
        regencyCode: regencyCode,
      );

      if (!mounted ||
          !_addresses.contains(address) ||
          requestVersion != address.regionRequestVersion) {
        return;
      }

      setState(() {
        address.districts = districts;
      });
    } catch (error) {
      if (!mounted ||
          !_addresses.contains(address) ||
          requestVersion != address.regionRequestVersion) {
        return;
      }

      setState(() {
        address.regionError = 'Gagal memuat kecamatan: $error';
      });
    } finally {
      if (mounted &&
          _addresses.contains(address) &&
          requestVersion == address.regionRequestVersion) {
        setState(() {
          address.isRegionLoading = false;
        });
      }
    }
  }

  Future<void> _selectDistrict(
    _AddressFormData address,
    String? districtCode,
  ) async {
    if (address.isLegacyRegion) return;

    final requestVersion = ++address.regionRequestVersion;

    setState(() {
      address.districtCode = districtCode;
      address.villageCode = null;

      address.villages = [];

      address.regionError = null;
      address.isRegionLoading = districtCode != null;
    });

    if (districtCode == null) return;

    final datasetId = address.regionDatasetId;
    if (datasetId == null) {
      if (mounted && _addresses.contains(address)) {
        setState(() {
          address.isRegionLoading = false;
          address.regionError = 'Dataset wilayah tidak tersedia.';
        });
      }
      return;
    }

    try {
      final villages = await _regionLocalDataSource.getVillages(
        datasetId: datasetId,
        districtCode: districtCode,
      );

      if (!mounted ||
          !_addresses.contains(address) ||
          requestVersion != address.regionRequestVersion) {
        return;
      }

      setState(() {
        address.villages = villages;
      });
    } catch (error) {
      if (!mounted ||
          !_addresses.contains(address) ||
          requestVersion != address.regionRequestVersion) {
        return;
      }

      setState(() {
        address.regionError = 'Gagal memuat desa/kelurahan: $error';
      });
    } finally {
      if (mounted &&
          _addresses.contains(address) &&
          requestVersion == address.regionRequestVersion) {
        setState(() {
          address.isRegionLoading = false;
        });
      }
    }
  }

  void _selectVillage(_AddressFormData address, String? villageCode) {
    if (address.isLegacyRegion) return;

    setState(() {
      address.villageCode = villageCode;
    });
  }

  Widget _buildRegionStatus(_AddressFormData address) {
    if (address.isRegionLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Memuat data wilayah...'),
          ],
        ),
      );
    }

    if (address.isLegacyRegion) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Alamat menggunakan referensi wilayah lama. '
          'Data historis tetap dipertahankan.',
        ),
      );
    }

    if (address.regionError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          address.regionError!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    if (address.regionDatasetId != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Dataset wilayah aktif siap. '
          '${address.provinces.length} provinsi tersedia.',
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildProvinceDropdown(_AddressFormData address) {
    if (address.countryCodeController.text.trim().toUpperCase() != 'ID') {
      return const SizedBox.shrink();
    }

    if (address.isLegacyRegion) {
      return const SizedBox.shrink();
    }

    if (address.regionDatasetId == null || address.provinces.isEmpty) {
      return const SizedBox.shrink();
    }

    return DropdownButtonFormField<String>(
      initialValue: address.provinceCode,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Provinsi',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Pilih provinsi'),
      items: address.provinces.map((province) {
        return DropdownMenuItem<String>(
          value: province.code,
          child: Text(province.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: address.isRegionLoading
          ? null
          : (value) => _selectProvince(address, value),
    );
  }

  Widget _buildRegencyDropdown(_AddressFormData address) {
    if (address.countryCodeController.text.trim().toUpperCase() != 'ID' ||
        address.isLegacyRegion ||
        address.provinceCode == null ||
        address.regencies.isEmpty) {
      return const SizedBox.shrink();
    }

    return DropdownButtonFormField<String>(
      initialValue: address.regencyCode,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Kabupaten/Kota',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Pilih kabupaten/kota'),
      items: address.regencies.map((regency) {
        return DropdownMenuItem<String>(
          value: regency.code,
          child: Text(regency.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: address.isRegionLoading
          ? null
          : (value) => _selectRegency(address, value),
    );
  }

  Widget _buildDistrictDropdown(_AddressFormData address) {
    if (address.countryCodeController.text.trim().toUpperCase() != 'ID' ||
        address.isLegacyRegion ||
        address.regencyCode == null ||
        address.districts.isEmpty) {
      return const SizedBox.shrink();
    }

    return DropdownButtonFormField<String>(
      initialValue: address.districtCode,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Kecamatan',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Pilih kecamatan'),
      items: address.districts.map((district) {
        return DropdownMenuItem<String>(
          value: district.code,
          child: Text(district.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: address.isRegionLoading
          ? null
          : (value) => _selectDistrict(address, value),
    );
  }

  Widget _buildVillageDropdown(_AddressFormData address) {
    if (address.countryCodeController.text.trim().toUpperCase() != 'ID' ||
        address.isLegacyRegion ||
        address.districtCode == null ||
        address.villages.isEmpty) {
      return const SizedBox.shrink();
    }

    return DropdownButtonFormField<String>(
      initialValue: address.villageCode,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Desa/Kelurahan',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Pilih desa/kelurahan'),
      items: address.villages.map((village) {
        return DropdownMenuItem<String>(
          value: village.code,
          child: Text(village.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: address.isRegionLoading
          ? null
          : (value) => _selectVillage(address, value),
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
  final ClientAddress? original;

  AddressType type;
  String? regionDatasetId;

  String? provinceCode;
  String? regencyCode;
  String? districtCode;
  String? villageCode;

  List<AdministrativeRegion> provinces = [];
  List<AdministrativeRegion> regencies = [];
  List<AdministrativeRegion> districts = [];
  List<AdministrativeRegion> villages = [];

  bool isRegionLoading = false;
  bool isLegacyRegion = false;
  String? regionError;

  // Mencegah hasil request wilayah lama menimpa pilihan terbaru.
  int regionRequestVersion = 0;

  final countryCodeController = TextEditingController(text: 'ID');
  final detailController = TextEditingController();
  final postalCodeController = TextEditingController();

  _AddressFormData() : original = null, type = AddressType.domicile;

  _AddressFormData.fromAddress(ClientAddress address)
    : original = address,
      type = address.addressType {
    countryCodeController.text = address.countryCode;
    detailController.text = address.addressDetail;
    postalCodeController.text = address.postalCode ?? '';

    regionDatasetId = address.regionDatasetId;
    provinceCode = address.provinceId;
    regencyCode = address.regencyId;
    districtCode = address.districtId;
    villageCode = address.villageId;
  }

  void dispose() {
    countryCodeController.dispose();
    detailController.dispose();
    postalCodeController.dispose();
  }
}
