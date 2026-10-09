import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_dependencies.dart';
import 'app_shell.dart';

class NotarisApp extends StatelessWidget {
  final AppDependencies dependencies;

  const NotarisApp({required this.dependencies, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: dependencies.clientBloc,
      child: MaterialApp(
        title: 'Notaris Apps',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: const AppShell(),
      ),
    );
  }
}
