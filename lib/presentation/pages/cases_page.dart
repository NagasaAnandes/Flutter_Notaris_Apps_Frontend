import 'package:flutter/material.dart';

import 'case_create_dialog.dart';

class CasesPage extends StatelessWidget {
  const CasesPage({super.key});

  Future<void> _openCreateDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CaseCreateDialog(),
    );

    if (!context.mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Case berhasil dibuat.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_copy_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Manajemen Case',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Buat Case baru untuk memulai proses pekerjaan notarial.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('create-case-button'),
              onPressed: () => _openCreateDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Buat Case Baru'),
            ),
          ],
        ),
      ),
    );
  }
}
