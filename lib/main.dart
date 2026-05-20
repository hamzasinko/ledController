import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'app_shell.dart';

void main() {
  runApp(const LedControllerApp());
}

class LedControllerApp extends StatelessWidget {
  const LedControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LED Controller',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AppShell(),
    );
  }
}
