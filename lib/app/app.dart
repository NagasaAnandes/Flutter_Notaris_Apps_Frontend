import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_dependencies.dart';
import 'app_shell.dart';
import '../presentation/bloc/case/case_bloc.dart';
import '../presentation/bloc/case_detail/case_detail_bloc.dart';
import '../presentation/bloc/client/client_bloc.dart';

class NotarisApp extends StatefulWidget {
  final AppDependencies dependencies;

  const NotarisApp({required this.dependencies, super.key});

  @override
  State<NotarisApp> createState() => _NotarisAppState();
}

class _NotarisAppState extends State<NotarisApp> {
  @override
  void dispose() {
    unawaited(widget.dependencies.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;

    return MultiBlocProvider(
      providers: [
        BlocProvider<ClientBloc>.value(value: dependencies.clientBloc),
        BlocProvider<CaseBloc>.value(value: dependencies.caseBloc),
        BlocProvider<CaseDetailBloc>.value(value: dependencies.caseDetailBloc),
      ],
      child: MaterialApp(
        title: 'Notaris Apps',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: const AppShell(),
      ),
    );
  }
}
