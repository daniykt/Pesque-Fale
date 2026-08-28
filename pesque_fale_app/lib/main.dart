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
import 'features/chat/data/conversas_api_client.dart';
import 'features/chat/data/conversas_repository.dart';
import 'features/chat/data/conversas_repository_http.dart';
import 'features/chat/data/conversas_repository_mock.dart';
import 'features/chat/domain/conversa.dart';
import 'features/chat/presentation/chat_page.dart';
import 'features/chat/presentation/inbox_page.dart';
import 'features/chat/providers/inbox_provider.dart';
import 'features/feed/data/comentarios_api_client.dart';
import 'features/feed/data/comentarios_repository.dart';
import 'features/feed/data/comentarios_repository_http.dart';
import 'features/feed/data/comentarios_repository_mock.dart';
import 'features/feed/data/curtidas_api_client.dart';
import 'features/feed/data/curtidas_repository.dart';
import 'features/feed/data/curtidas_repository_http.dart';
import 'features/feed/data/curtidas_repository_mock.dart';
import 'features/feed/data/eventos_api_client.dart';
import 'features/feed/data/eventos_repository.dart';
import 'features/feed/data/eventos_repository_http.dart';
import 'features/feed/data/eventos_repository_mock.dart';
import 'features/feed/data/publicacoes_api_client.dart';
import 'features/feed/data/publicacoes_repository.dart';
import 'features/feed/data/publicacoes_repository_http.dart';
import 'features/feed/data/publicacoes_repository_mock.dart';
import 'features/feed/data/upload_publicacao_imagem_api_client.dart';
import 'features/feed/data/upload_publicacao_imagem_repository.dart';
import 'features/feed/data/upload_publicacao_imagem_repository_http.dart';
import 'features/feed/data/upload_publicacao_imagem_repository_mock.dart';
import 'features/feed/domain/publicacao.dart';
import 'features/feed/providers/feed_provider.dart';
import 'features/onboarding/domain/onboarding_status_storage.dart';
import 'features/onboarding/presentation/onboarding_wizard_page.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
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
import 'features/nova_publicacao/presentation/nova_publicacao_page.dart';
import 'features/nova_publicacao/providers/nova_publicacao_provider.dart';
import 'features/notificacoes/data/notificacoes_api_client.dart';
import 'features/notificacoes/data/notificacoes_repository.dart';
import 'features/notificacoes/data/notificacoes_repository_http.dart';
import 'features/notificacoes/data/notificacoes_repository_mock.dart';
import 'features/notificacoes/providers/badge_notificacoes_provider.dart';
import 'features/ponto_detalhe/presentation/ponto_detalhe_page.dart';
import 'features/ponto_detalhe/providers/ponto_detalhe_provider.dart';
import 'features/visualizacao_post/presentation/publicacao_detalhe_page.dart';
import 'features/visualizacao_post/providers/publicacao_detalhe_provider.dart';
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

  final PublicacoesRepository publicacoesRepository = AppConfig.useMock
      ? PublicacoesRepositoryMock()
      : PublicacoesRepositoryHttp(
          apiClient: PublicacoesApiClient(
            baseUrl: AppConfig.apiBaseUrl,
            tokenStorage: tokenStorage,
          ),
        );

  final CurtidasRepository curtidasRepository = AppConfig.useMock
      ? CurtidasRepositoryMock()
      : CurtidasRepositoryHttp(
          apiClient: CurtidasApiClient(
            baseUrl: AppConfig.apiBaseUrl,
            tokenStorage: tokenStorage,
          ),
        );

  final ComentariosRepository comentariosRepository = AppConfig.useMock
      ? ComentariosRepositoryMock()
      : ComentariosRepositoryHttp(
          apiClient: ComentariosApiClient(
            baseUrl: AppConfig.apiBaseUrl,
            tokenStorage: tokenStorage,
          ),
        );

  final EventosRepository eventosRepository = AppConfig.useMock
      ? EventosRepositoryMock()
      : EventosRepositoryHttp(
          apiClient: EventosApiClient(baseUrl: AppConfig.apiBaseUrl),
        );

  final ConversasRepository conversasRepository = AppConfig.useMock
      ? ConversasRepositoryMock()
      : ConversasRepositoryHttp(
          apiClient: ConversasApiClient(
            baseUrl: AppConfig.apiBaseUrl,
            tokenStorage: tokenStorage,
          ),
        );

  final NotificacoesRepository notificacoesRepository = AppConfig.useMock
      ? NotificacoesRepositoryMock()
      : NotificacoesRepositoryHttp(
          apiClient: NotificacoesApiClient(
            baseUrl: AppConfig.apiBaseUrl,
            tokenStorage: tokenStorage,
          ),
        );

  final UploadPublicacaoImagemRepository uploadPublicacaoImagemRepository =
      AppConfig.useMock
      ? UploadPublicacaoImagemRepositoryMock()
      : UploadPublicacaoImagemRepositoryHttp(
          apiClient: UploadPublicacaoImagemApiClient(
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
        Provider<PerfilRepository>.value(value: perfilRepository),
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
        Provider<PublicacoesRepository>.value(value: publicacoesRepository),
        Provider<CurtidasRepository>.value(value: curtidasRepository),
        Provider<ComentariosRepository>.value(value: comentariosRepository),
        Provider<EventosRepository>.value(value: eventosRepository),
        Provider<ConversasRepository>.value(value: conversasRepository),
        Provider<NotificacoesRepository>.value(value: notificacoesRepository),
        ChangeNotifierProvider<BadgeNotificacoesProvider>(
          create: (ctx) =>
              BadgeNotificacoesProvider(repository: ctx.read<NotificacoesRepository>())
                ..atualizar(),
        ),
        Provider<UploadPublicacaoImagemRepository>.value(
          value: uploadPublicacaoImagemRepository,
        ),
        ChangeNotifierProxyProvider<AuthProvider, FeedProvider>(
          create: (context) => FeedProvider(
            publicacoesRepo: publicacoesRepository,
            curtidasRepo: curtidasRepository,
            eventosRepo: eventosRepository,
            pontosRepo: pontosRepository,
            authProvider: context.read<AuthProvider>(),
          ),
          update: (context, auth, previous) => previous!..reagirAuth(auth),
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
        '/onboarding': (context) => ChangeNotifierProvider<OnboardingProvider>(
          create: (ctx) => OnboardingProvider(
            perfilRepository: ctx.read<PerfilRepository>(),
            authProvider: ctx.read<AuthProvider>(),
            statusStorage: OnboardingStatusStorage(),
          ),
          child: const OnboardingWizardPage(),
        ),
        '/home': (_) => MainShell(key: MainShell.shellKey),
        '/perfil/editar': (_) => const EditarPerfilPage(),
        '/publicar': (_) =>
            const AppEmConstrucaoPage(titulo: 'Nova publicação'),
        '/publicacao/nova': (context) =>
            ChangeNotifierProvider<NovaPublicacaoProvider>(
              create: (ctx) => NovaPublicacaoProvider(
                publicacoesRepository: ctx.read<PublicacoesRepository>(),
                uploadRepository: ctx.read<UploadPublicacaoImagemRepository>(),
                feedProvider: ctx.read<FeedProvider>(),
                authProvider: ctx.read<AuthProvider>(),
              ),
              child: const NovaPublicacaoPage(),
            ),
        '/chat': (context) => ChangeNotifierProvider<InboxProvider>(
          create: (ctx) =>
              InboxProvider(repository: ctx.read<ConversasRepository>()),
          child: const InboxPage(),
        ),
        '/sobre': (_) => const AppEmConstrucaoPage(titulo: 'Sobre Nós'),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/chat/conversa') {
          final conversa = settings.arguments as Conversa;
          return MaterialPageRoute(
            builder: (_) => ChatPage(conversa: conversa),
          );
        }
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
        if (settings.name == '/publicacao/detalhe') {
          final args = settings.arguments;
          final Publicacao? publicacaoInicial = args is Publicacao
              ? args
              : null;
          final String? publicacaoId = args is String ? args : null;
          if (publicacaoInicial == null && publicacaoId == null) return null;

          return MaterialPageRoute(
            builder: (context) =>
                ChangeNotifierProvider<PublicacaoDetalheProvider>(
                  create: (ctx) => PublicacaoDetalheProvider(
                    publicacoesRepository: ctx.read<PublicacoesRepository>(),
                    publicacaoInicial: publicacaoInicial,
                    publicacaoId: publicacaoId,
                  )..carregar(),
                  child: const PublicacaoDetalhePage(),
                ),
          );
        }
        return null;
      },
    );
  }
}
