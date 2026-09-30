import 'package:flutter/material.dart';

class NotarisApp extends StatelessWidget {
  const NotarisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notaris Apps',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const Scaffold(body: Center(child: Text('Notaris Apps'))),
    );
  }
}
