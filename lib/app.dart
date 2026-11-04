import 'package:flutter/material.dart';

import 'theme.dart';
import 'ui/splash_gate.dart';

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Do it now',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashGate(),
    );
  }
}
