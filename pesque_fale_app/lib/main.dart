import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/router/main_shell.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/data/auth_api_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/auth_repository_http.dart';
import 'features/auth/data/auth_repository_mock.dart';
import 'features/auth/data/token_storage.dart';
import 'features/auth/presentation/cadastro/cadastro_page.dart';
import 'features/auth/presentation/login/login_page.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/onboarding/onboarding_placeholder_page.dart';

void main() {
  final tokenStorage = TokenStorage();
  final AuthRepository authRepository = AppConfig.useMock
      ? AuthRepositoryMock(tokenStorage: tokenStorage)
      : AuthRepositoryHttp(
          apiClient: AuthApiClient(baseUrl: AppConfig.apiBaseUrl),
          tokenStorage: tokenStorage,
        );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(repository: authRepository)),
      ],
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
      initialRoute: '/cadastro',
      routes: {
        '/cadastro': (_) => const CadastroPage(),
        '/login': (_) => const LoginPage(),
        '/onboarding': (_) => const OnboardingPlaceholderPage(),
        '/home': (_) => const MainShell(),
      },
    );
  }
}
