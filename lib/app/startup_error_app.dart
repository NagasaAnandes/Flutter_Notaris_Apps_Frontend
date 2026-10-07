import 'package:flutter/material.dart';

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({
    required this.error,
    required this.stackTrace,
    super.key,
  });

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notaris Apps',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Database initialization failed',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aplikasi tidak dapat menyiapkan database lokal.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  SelectableText(error.toString()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
