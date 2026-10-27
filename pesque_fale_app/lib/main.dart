import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/realtime/realtime_manager.dart';
import 'core/router/main_shell.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/assistente/data/assistente_api_client.dart';
import 'features/assistente/data/assistente_repository.dart';
import 'features/assistente/data/assistente_repository_http.dart';
import 'features/assistente/data/assistente_repository_mock.dart';
import 'features/assistente/presentation/assistente_page.dart';
import 'features/assistente/providers/assistente_provider.dart';
import 'features/auth/data/auth_api_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/auth_repository_http.dart';
import 'features/auth/data/auth_repository_mock.dart';
import 'features/auth/data/token_storage.dart';
import 'features/auth/presentation/cadastro/cadastro_page.dart';
import 'features/auth/presentation/entrando/entrando_page.dart';
import 'features/auth/presentation/login/login_page.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/chat/data/conversas_api_client.dart';
import 'features/chat/data/conversas_repository.dart';
import 'features/chat/data/conversas_repository_http.dart';
import 'features/chat/data/conversas_repository_mock.dart';
import 'features/chat/domain/conversa.dart';
import 'features/chat/presentation/chat_page.dart';
import 'features/chat/presentation/inbox_page.dart';
import 'features/chat/providers/badge_mensagens_provider.dart';
import 'features/chat/providers/inbox_provider.dart';
import 'features/configuracoes/presentation/configuracoes_page.dart';
import 'features/configuracoes/providers/preferencias_provider.dart';
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
import 'features/feed/domain/aba_feed.dart';
import 'features/feed/domain/publicacao.dart';
import 'features/feed/providers/feed_provider.dart';
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
import 'features/notificacoes/providers/notificacoes_provider.dart';
import 'features/ponto_detalhe/presentation/ponto_detalhe_page.dart';
import 'features/ponto_detalhe/providers/ponto_detalhe_provider.dart';
import 'features/sobre/presentation/sobre_page.dart';
import 'features/tour/domain/tour_status_storage.dart';
import 'features/tour/providers/tour_provider.dart';
import 'features/visualizacao_post/presentation/publicacao_detalhe_page.dart';
import 'features/visualizacao_post/providers/publicacao_detalhe_provider.dart';

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

  final AssistenteRepository assistenteRepository = AppConfig.useMock
      ? AssistenteRepositoryMock()
      : AssistenteRepositoryHttp(
          apiClient: AssistenteApiClient(
            baseUrl: AppConfig.apiBaseUrl,
            tokenStorage: tokenStorage,
          ),
        );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PreferenciasProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repository: authRepository),
        ),
        ChangeNotifierProxyProvider<AuthProvider, RealtimeManager>(
          // Ninguém lê o manager ainda; sem lazy: false ele nunca seria
          // criado e o socket não conectaria no login.
          lazy: false,
          create: (_) => RealtimeManager(),
          update: (context, auth, previous) => previous!..reagirAuth(auth),
        ),
        Provider<PerfilRepository>.value(value: perfilRepository),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          RealtimeManager,
          PerfilProvider
        >(
          // Precisa estar vivo pra receber eventos de seguidor mesmo quando o
          // usuário está em outra aba (abriu Chat, mas alguém o seguiu).
          lazy: false,
          create: (ctx) => PerfilProvider(
            repository: perfilRepository,
            authProvider: ctx.read<AuthProvider>(),
            realtime: ctx.read<RealtimeManager>(),
          ),
          update: (ctx, auth, realtime, previous) =>
              previous!..rebindAuth(auth),
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
        ChangeNotifierProxyProvider2<
          AuthProvider,
          RealtimeManager,
          NotificacoesProvider
        >(
          // Precisa estar vivo pra receber eventos mesmo sem a aba Alertas
          // aberta — é dele que o badge de notificações deriva.
          lazy: false,
          create: (ctx) => NotificacoesProvider(
            repository: ctx.read<NotificacoesRepository>(),
            perfilRepository: ctx.read<PerfilRepository>(),
            realtime: ctx.read<RealtimeManager>(),
          ),
          update: (ctx, auth, realtime, previous) =>
              previous!..reagirAuth(auth),
        ),
        ChangeNotifierProxyProvider<
          NotificacoesProvider,
          BadgeNotificacoesProvider
        >(
          create: (ctx) => BadgeNotificacoesProvider(
            notificacoes: ctx.read<NotificacoesProvider>(),
          ),
          update: (ctx, notificacoes, previous) =>
              previous ?? BadgeNotificacoesProvider(notificacoes: notificacoes),
        ),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          RealtimeManager,
          InboxProvider
        >(
          // Precisa estar vivo pra receber eventos mesmo sem a aba Chat
          // aberta — é dele que o badge de mensagens deriva.
          lazy: false,
          create: (ctx) => InboxProvider(
            repository: ctx.read<ConversasRepository>(),
            realtime: ctx.read<RealtimeManager>(),
          ),
          update: (ctx, auth, realtime, previous) =>
              previous!..reagirAuth(auth),
        ),
        ChangeNotifierProxyProvider<InboxProvider, BadgeMensagensProvider>(
          create: (ctx) =>
              BadgeMensagensProvider(inbox: ctx.read<InboxProvider>()),
          update: (ctx, inbox, previous) =>
              previous ?? BadgeMensagensProvider(inbox: inbox),
        ),
        Provider<UploadPublicacaoImagemRepository>.value(
          value: uploadPublicacaoImagemRepository,
        ),
        Provider<AssistenteRepository>.value(value: assistenteRepository),
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
        Provider<TourStatusStorage>(create: (_) => TourStatusStorage()),
        ChangeNotifierProvider<TourProvider>(
          create: (ctx) => TourProvider(
            storage: ctx.read<TourStatusStorage>(),
            authProvider: ctx.read<AuthProvider>(),
          ),
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
          ),
          child: const OnboardingWizardPage(),
        ),
        '/entrando': (context) => EntrandoPage(
          preparar: () =>
              context.read<FeedProvider>().trocarAba(AbaFeed.paraVoce),
        ),
        '/perfil/editar': (_) => const EditarPerfilPage(),
        '/configuracoes': (_) => const ConfiguracoesPage(),
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
        '/chat': (_) => const InboxPage(),
        '/sobre': (_) => const SobrePage(),
        '/assistente': (context) => ChangeNotifierProvider<AssistenteProvider>(
          create: (ctx) =>
              AssistenteProvider(repository: ctx.read<AssistenteRepository>()),
          child: const AssistentePage(),
        ),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          return PageRouteBuilder<void>(
            settings: settings,
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, _, _) => MainShell(key: MainShell.shellKey),
            transitionsBuilder: (_, animacao, _, child) =>
                FadeTransition(opacity: animacao, child: child),
          );
        }
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
