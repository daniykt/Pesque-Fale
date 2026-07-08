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
import 'features/perfil/data/perfil_api_client.dart';
import 'features/perfil/data/perfil_repository.dart';
import 'features/perfil/data/perfil_repository_http.dart';
import 'features/perfil/data/perfil_repository_mock.dart';
import 'features/perfil/presentation/editar_perfil/editar_perfil_page.dart';
import 'features/perfil/presentation/perfil_de_outro_page.dart';
import 'features/perfil/providers/perfil_provider.dart';
import 'features/pesquisa/data/pontos_api_client.dart';
import 'features/pesquisa/data/pontos_repository.dart';
import 'features/pesquisa/data/pontos_repository_http.dart';
import 'features/pesquisa/data/pontos_repository_mock.dart';
import 'features/pesquisa/providers/pesquisa_locais_provider.dart';
import 'features/ponto_detalhe/data/avaliacoes_api_client.dart';
import 'features/ponto_detalhe/data/avaliacoes_repository.dart';
import 'features/ponto_detalhe/data/avaliacoes_repository_http.dart';
import 'features/ponto_detalhe/data/avaliacoes_repository_mock.dart';
import 'features/ponto_detalhe/presentation/ponto_detalhe_page.dart';
import 'features/ponto_detalhe/providers/ponto_detalhe_provider.dart';
import 'shared/widgets/app_em_construcao_page.dart';

void main() {
  final tokenStorage = TokenStorage();
  final AuthRepository authRepository = AppConfig.useMock
      ? AuthRepositoryMock(tokenStorage: tokenStorage)
      : AuthRepositoryHttp(
          apiClient: AuthApiClient(baseUrl: AppConfig.apiBaseUrl),
          tokenStorage: tokenStorage,
        );

  final PerfilRepository perfilRepository = AppConfig.useMock
      ? PerfilRepositoryMock()
      : PerfilRepositoryHttp(
          apiClient: PerfilApiClient(
            baseUrl: AppConfig.apiBaseUrl,
            tokenStorage: tokenStorage,
          ),
        );

  final PontosRepository pontosRepository = AppConfig.useMock
      ? PontosRepositoryMock()
      : PontosRepositoryHttp(
          apiClient: PontosApiClient(
            baseUrl: AppConfig.apiBaseUrl,
            tokenStorage: tokenStorage,
          ),
        );

  final AvaliacoesRepository avaliacoesRepository = AppConfig.useMock
      ? AvaliacoesRepositoryMock()
      : AvaliacoesRepositoryHttp(
          apiClient: AvaliacoesApiClient(
            baseUrl: AppConfig.apiBaseUrl,
            tokenStorage: tokenStorage,
          ),
        );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repository: authRepository),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PerfilProvider>(
          create: (context) => PerfilProvider(
            repository: perfilRepository,
            authProvider: context.read<AuthProvider>(),
          ),
          update: (context, auth, previous) => previous!..authProvider = auth,
        ),
        Provider<PontosRepository>.value(value: pontosRepository),
        Provider<AvaliacoesRepository>.value(value: avaliacoesRepository),
        ChangeNotifierProvider(
          create: (_) =>
              PesquisaLocaisProvider(repository: pontosRepository)
                ..inicializar(),
        ),
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
        '/home': (_) => MainShell(key: MainShell.shellKey),
        '/perfil/editar': (_) => const EditarPerfilPage(),
        '/publicar': (_) =>
            const AppEmConstrucaoPage(titulo: 'Nova publicação'),
        '/chat': (_) => const AppEmConstrucaoPage(titulo: 'Chat'),
        '/sobre': (_) => const AppEmConstrucaoPage(titulo: 'Sobre Nós'),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/perfil') {
          final usuarioId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider<PerfilProvider>(
              create: (ctx) => PerfilProvider(
                repository: ctx.read<PerfilProvider>().repository,
                authProvider: ctx.read<AuthProvider>(),
              ),
              child: PerfilDeOutroPage(usuarioId: usuarioId),
            ),
          );
        }
        if (settings.name == '/pontos') {
          final pontoId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider<PontoDetalheProvider>(
              create: (ctx) => PontoDetalheProvider(
                pontosRepository: ctx.read<PontosRepository>(),
                avaliacoesRepository: ctx.read<AvaliacoesRepository>(),
                authProvider: ctx.read<AuthProvider>(),
              ),
              child: PontoDetalhePage(pontoId: pontoId),
            ),
          );
        }
        return null;
      },
    );
  }
}
