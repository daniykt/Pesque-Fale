import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router/main_shell.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const PesqueFaleApp(),
    ),
  );
}

class PesqueFaleApp extends StatelessWidget {
  const PesqueFaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;
    return MaterialApp(
      title: 'Pesque & Fale',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const MainShell(),
    );
  }
}
