import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pesque_fale_app/core/data/paged_result.dart';
import 'package:pesque_fale_app/core/realtime/realtime_manager.dart';
import 'package:pesque_fale_app/core/router/main_shell.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/assistente/presentation/widgets/botao_ajuda_assistente.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/presentation/entrando/entrando_page.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/chat/data/conversas_repository.dart';
import 'package:pesque_fale_app/features/chat/domain/conversa.dart';
import 'package:pesque_fale_app/features/chat/providers/badge_mensagens_provider.dart';
import 'package:pesque_fale_app/features/chat/providers/inbox_provider.dart';
import 'package:pesque_fale_app/features/clima/data/clima_repository.dart';
import 'package:pesque_fale_app/features/clima/data/localizacao_service.dart';
import 'package:pesque_fale_app/features/clima/domain/clima.dart';
import 'package:pesque_fale_app/features/clima/domain/condicao_clima.dart';
import 'package:pesque_fale_app/features/clima/providers/clima_provider.dart';
import 'package:pesque_fale_app/features/feed/data/comentarios_repository.dart';
import 'package:pesque_fale_app/features/feed/data/curtidas_repository.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_repository.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/aba_feed.dart';
import 'package:pesque_fale_app/features/feed/domain/comentario.dart';
import 'package:pesque_fale_app/features/feed/domain/evento.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/presentation/widgets/abas_scroll.dart';
import 'package:pesque_fale_app/features/feed/providers/feed_provider.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';
import 'package:pesque_fale_app/features/notificacoes/data/notificacoes_repository.dart';
import 'package:pesque_fale_app/features/notificacoes/domain/notificacao.dart';
import 'package:pesque_fale_app/features/notificacoes/providers/badge_notificacoes_provider.dart';
import 'package:pesque_fale_app/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository.dart';
import 'package:pesque_fale_app/features/perfil/domain/perfil_completo.dart';
import 'package:pesque_fale_app/features/perfil/providers/perfil_provider.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_repository.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/filtros_locais.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/ponto.dart';
import 'package:pesque_fale_app/features/pesquisa/providers/pesquisa_locais_provider.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/data/avaliacoes_repository.dart';
import 'package:pesque_fale_app/features/tour/domain/tour_status_storage.dart';
import 'package:pesque_fale_app/features/tour/presentation/widgets/tour_card.dart';
import 'package:pesque_fale_app/features/tour/providers/tour_provider.dart';
import 'package:pesque_fale_app/shared/widgets/badge_equipe/badge_equipe.dart';
import 'package:pesque_fale_app/shared/widgets/badge_equipe/tipo_badge.dart';

import '../../features/chat/support/fake_realtime_manager.dart';

// Regressão da #272: as abas da Home (Para você, Seguindo, Eventos, Locais,
// Dicas) pararam de responder ao toque na v1.0.0. Aqui o MainShell é montado
// inteiro (as 5 telas do menu inferior, o tour e o botão Ajuda), na largura
// de um celular real, e cada toque confere duas coisas: que o hit test no
// centro do chip chega ao InkWell dele (nada por cima) e que a aba troca.
//
// Repositórios falsos, sem rede e sem imagem.

const _usuarioLogado = Usuario(
  id: 'eu',
  nome: 'Ana',
  email: 'ana@teste.com',
  onboardingConcluido: true,
);

Publicacao _publicacao(int i, {String autorId = 'autor-0'}) => Publicacao(
  id: 'pub-$i',
  autorId: autorId,
  autorNome: 'Pescador $i',
  descricao: 'Relato de pescaria número $i.',
  criadoEm: DateTime(2026, 1, 1),
  atualizadoEm: DateTime(2026, 1, 1),
);

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async => const AuthResult(accessToken: 'token', usuario: _usuarioLogado);

  @override
  Future<void> logout() async {}

  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) async => throw UnimplementedError();
}

class _FakePublicacoesRepository implements PublicacoesRepository {
  _FakePublicacoesRepository(this.paraVoce);

  final List<Publicacao> paraVoce;

  @override
  Future<PagedResult<Publicacao>> listar({
    int pagina = 1,
    int porPagina = 20,
    bool seguindo = false,
  }) async {
    final itens = pagina > 1
        ? const <Publicacao>[]
        : (seguindo ? [_publicacao(99, autorId: 'seguido')] : paraVoce);
    return PagedResult(
      items: itens,
      total: pagina > 1 ? 0 : itens.length,
      pagina: pagina,
      porPagina: porPagina,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCurtidasRepository implements CurtidasRepository {
  @override
  Future<void> curtir(String publicacaoId) async {}

  @override
  Future<void> descurtir(String publicacaoId) async {}
}

class _FakeComentariosRepository implements ComentariosRepository {
  @override
  Future<PagedResult<Comentario>> listar(
    String publicacaoId, {
    int pagina = 1,
    int porPagina = 20,
  }) async => const PagedResult(items: [], total: 0, pagina: 1, porPagina: 20);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEventosRepository implements EventosRepository {
  @override
  Future<List<Evento>> listar({bool futuros = true, int limite = 10}) async => [
    Evento(
      id: 'evento-0',
      titulo: 'Torneio de Pesca de Verão',
      organizadorId: 'autor-0',
      organizadorNome: 'Clube de Pesca',
      dataInicio: DateTime.now().add(const Duration(days: 3)),
      criadoEm: DateTime.now(),
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePontosRepository implements PontosRepository {
  @override
  Future<List<Ponto>> buscar({
    required FiltrosLocais filtros,
    double? lat,
    double? lng,
    bool incluirDistancia = false,
    String? ordem,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePerfilRepository implements PerfilRepository {
  @override
  Future<PerfilCompleto> buscarPerfil(
    String id, {
    required String meuId,
  }) async => const PerfilCompleto(usuario: _usuarioLogado);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeConversasRepository implements ConversasRepository {
  @override
  Future<List<Conversa>> listar() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNotificacoesRepository implements NotificacoesRepository {
  @override
  Future<({List<Notificacao> lista, int naoLidas})> listar({
    int pagina = 1,
    int porPagina = 20,
  }) async => (lista: const <Notificacao>[], naoLidas: 0);

  @override
  Future<int> contarNaoLidas() async => 0;

  @override
  Future<void> marcarTodasComoLidas() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAvaliacoesRepository implements AvaliacoesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeClimaRepository implements ClimaRepository {
  @override
  Future<Clima> buscarAtual({
    required double latitude,
    required double longitude,
  }) async => const Clima(
    temperatura: 21.6,
    umidade: 83,
    ventoKmh: 7.2,
    condicao: CondicaoClima.chuva,
  );
}

class _FakeLocalizacao implements LocalizacaoService {
  @override
  Future<ResultadoLocalizacao> obter({required bool pedirPermissao}) async =>
      const LocalizacaoObtida(latitude: -21.6, longitude: -48.36);

  @override
  Future<void> abrirConfiguracoes(MotivoSemLocalizacao motivo) async {}
}

/// Canal do flutter_secure_storage em memória: o `pular()` do tour grava
/// "tour visto" por ele.
void _fakeSecureStorage() {
  final dados = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async {
          final args = (call.arguments as Map).cast<String, dynamic>();
          final chave = args['key'] as String?;
          switch (call.method) {
            case 'read':
              return dados[chave];
            case 'write':
              dados[chave!] = args['value'] as String;
              return null;
            case 'delete':
              dados.remove(chave);
              return null;
            case 'containsKey':
              return dados.containsKey(chave);
            case 'readAll':
              return dados;
            case 'deleteAll':
              dados.clear();
              return null;
          }
          return null;
        },
      );
}

/// Mesma árvore de providers do `main.dart`, com repositórios falsos.
Future<Widget> _app({
  List<Publicacao>? paraVoce,
  Widget home = const MainShell(),
  Map<String, WidgetBuilder> rotas = const {},
  RouteFactory? onGenerateRoute,
  String? initialRoute,
}) async {
  final auth = AuthProvider(repository: _FakeAuthRepository());
  await auth.login(email: 'ana@teste.com', senha: 'senha');

  final publicacoesRepo = _FakePublicacoesRepository(
    paraVoce ?? [for (var i = 0; i < 3; i++) _publicacao(i)],
  );
  final curtidasRepo = _FakeCurtidasRepository();
  final eventosRepo = _FakeEventosRepository();
  final pontosRepo = _FakePontosRepository();
  final perfilRepo = _FakePerfilRepository();
  final store = PublicacoesStore();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProxyProvider<AuthProvider, RealtimeManager>(
        lazy: false,
        create: (_) => FakeRealtimeManager(),
        update: (_, auth, previous) => previous!..reagirAuth(auth),
      ),
      ChangeNotifierProvider<PublicacoesStore>.value(value: store),
      Provider<PerfilRepository>.value(value: perfilRepo),
      ChangeNotifierProxyProvider2<
        AuthProvider,
        RealtimeManager,
        PerfilProvider
      >(
        lazy: false,
        create: (ctx) => PerfilProvider(
          repository: perfilRepo,
          authProvider: ctx.read<AuthProvider>(),
          store: store,
          realtime: ctx.read<RealtimeManager>(),
        ),
        update: (_, auth, _, previous) => previous!..rebindAuth(auth),
      ),
      Provider<PontosRepository>.value(value: pontosRepo),
      ChangeNotifierProvider<ClimaProvider>(
        create: (_) => ClimaProvider(
          repository: _FakeClimaRepository(),
          localizacao: _FakeLocalizacao(),
        ),
      ),
      Provider<AvaliacoesRepository>.value(value: _FakeAvaliacoesRepository()),
      ChangeNotifierProvider<PesquisaLocaisProvider>(
        create: (_) => PesquisaLocaisProvider(repository: pontosRepo),
      ),
      Provider<PublicacoesRepository>.value(value: publicacoesRepo),
      Provider<CurtidasRepository>.value(value: curtidasRepo),
      Provider<ComentariosRepository>.value(
        value: _FakeComentariosRepository(),
      ),
      Provider<EventosRepository>.value(value: eventosRepo),
      Provider<ConversasRepository>.value(value: _FakeConversasRepository()),
      Provider<NotificacoesRepository>.value(
        value: _FakeNotificacoesRepository(),
      ),
      ChangeNotifierProxyProvider2<
        AuthProvider,
        RealtimeManager,
        NotificacoesProvider
      >(
        lazy: false,
        create: (ctx) => NotificacoesProvider(
          repository: ctx.read<NotificacoesRepository>(),
          perfilRepository: perfilRepo,
          realtime: ctx.read<RealtimeManager>(),
        ),
        update: (_, auth, _, previous) => previous!..reagirAuth(auth),
      ),
      ChangeNotifierProxyProvider<
        NotificacoesProvider,
        BadgeNotificacoesProvider
      >(
        create: (ctx) => BadgeNotificacoesProvider(
          notificacoes: ctx.read<NotificacoesProvider>(),
        ),
        update: (_, notificacoes, previous) =>
            previous ?? BadgeNotificacoesProvider(notificacoes: notificacoes),
      ),
      ChangeNotifierProxyProvider2<
        AuthProvider,
        RealtimeManager,
        InboxProvider
      >(
        lazy: false,
        create: (ctx) => InboxProvider(
          repository: ctx.read<ConversasRepository>(),
          realtime: ctx.read<RealtimeManager>(),
        ),
        update: (_, auth, _, previous) => previous!..reagirAuth(auth),
      ),
      ChangeNotifierProxyProvider<InboxProvider, BadgeMensagensProvider>(
        create: (ctx) =>
            BadgeMensagensProvider(inbox: ctx.read<InboxProvider>()),
        update: (_, inbox, previous) =>
            previous ?? BadgeMensagensProvider(inbox: inbox),
      ),
      ChangeNotifierProxyProvider2<AuthProvider, RealtimeManager, FeedProvider>(
        lazy: false,
        create: (ctx) => FeedProvider(
          publicacoesRepo: publicacoesRepo,
          curtidasRepo: curtidasRepo,
          eventosRepo: eventosRepo,
          pontosRepo: pontosRepo,
          authProvider: ctx.read<AuthProvider>(),
          realtime: ctx.read<RealtimeManager>(),
          store: store,
        ),
        update: (_, auth, _, previous) => previous!..reagirAuth(auth),
      ),
      Provider<TourStatusStorage>(
        create: (_) => TourStatusStorage(storage: const FlutterSecureStorage()),
      ),
      ChangeNotifierProvider<TourProvider>(
        create: (ctx) => TourProvider(
          storage: ctx.read<TourStatusStorage>(),
          authProvider: auth,
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: initialRoute == null ? home : null,
      initialRoute: initialRoute,
      routes: rotas,
      onGenerateRoute: onGenerateRoute,
    ),
  );
}

/// Tela de um celular real: 360×800 dp. Nessa largura a aba Dicas fica
/// fora da tela e só aparece rolando a fileira.
void _telaDeCelular(WidgetTester tester) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(1080, 2400);
  addTearDown(tester.view.reset);
}

Finder _chip(AbaFeed aba) => find.ancestor(
  of: find.descendant(
    of: find.byType(AbasScroll),
    matching: find.text(aba.label),
  ),
  matching: find.byType(InkWell),
);

FeedProvider _feed(WidgetTester tester) =>
    tester.element(find.byType(AbasScroll)).read<FeedProvider>();

/// Toca no centro do chip da [aba] e confere que o toque chegou ao InkWell
/// dele e que a aba trocou e ficou destacada.
Future<void> _tocarAba(WidgetTester tester, AbaFeed aba) async {
  final chip = _chip(aba);
  expect(chip, findsOneWidget, reason: 'chip ${aba.label}');
  final centro = tester.getCenter(chip);

  final tela = tester.view.physicalSize / tester.view.devicePixelRatio;
  expect(
    (Offset.zero & tela).contains(centro),
    isTrue,
    reason: 'centro do chip ${aba.label} ($centro) fora da tela $tela',
  );

  // O GestureDetector do InkWell é quem recebe o ponteiro: se ele não está
  // no caminho do hit test, alguma coisa por cima engoliu o toque.
  final detector = tester.renderObject(
    find.descendant(of: chip, matching: find.byType(RawGestureDetector)).first,
  );
  final caminho = tester.hitTestOnBinding(centro).path;
  expect(
    caminho.any((entrada) => identical(entrada.target, detector)),
    isTrue,
    reason:
        'hit test no centro do chip ${aba.label} não chegou ao InkWell. '
        'Primeiro alvo: ${caminho.first.target.runtimeType}',
  );

  await tester.tap(chip);
  await tester.pumpAndSettle();

  expect(_feed(tester).abaAtiva, aba);
  final cor = Theme.of(
    tester.element(find.byType(AbasScroll)),
  ).extension<AppColors>()!.primary;
  for (final outra in AbaFeed.values) {
    final caixa =
        tester
                .widgetList<Container>(
                  find.descendant(
                    of: _chip(outra),
                    matching: find.byType(Container),
                  ),
                )
                .first
                .decoration!
            as BoxDecoration;
    expect(
      caixa.color == cor,
      outra == aba,
      reason: 'destaque do chip ${outra.label} com ${aba.label} ativa',
    );
  }
}

/// Garante o chip visível (rola a fileira de abas se preciso) e toca.
Future<void> _rolarETocar(WidgetTester tester, AbaFeed aba) async {
  await tester.ensureVisible(_chip(aba));
  await tester.pumpAndSettle();
  await _tocarAba(tester, aba);
}

/// Para você → Seguindo → Eventos → Locais → Dicas → Para você.
Future<void> _tocarTodas(WidgetTester tester) async {
  for (final aba in [...AbaFeed.values, AbaFeed.paraVoce]) {
    await _rolarETocar(tester, aba);
  }
}

Finder _destino(String rotulo) => find.descendant(
  of: find.byType(NavigationBar),
  matching: find.text(rotulo),
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _fakeSecureStorage();
  });

  testWidgets('1. toca nas 5 abas em sequência', (tester) async {
    _telaDeCelular(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    expect(_feed(tester).abaAtiva, AbaFeed.paraVoce);
    await _tocarTodas(tester);
  });

  testWidgets('1b. arrasta a fileira até a Dicas e volta para a Para você', (
    tester,
  ) async {
    _telaDeCelular(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    // Em 360 dp a Dicas começa fora da tela.
    final larguraTela =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(tester.getCenter(_chip(AbaFeed.dicas)).dx, greaterThan(larguraTela));

    await tester.drag(find.byType(AbasScroll), const Offset(-400, 0));
    await tester.pumpAndSettle();
    await _tocarAba(tester, AbaFeed.dicas);

    await tester.drag(find.byType(AbasScroll), const Offset(400, 0));
    await tester.pumpAndSettle();
    await _tocarAba(tester, AbaFeed.paraVoce);
  });

  testWidgets('1c. toca nas 5 abas com fonte grande (textScaler 1.3)', (
    tester,
  ) async {
    _telaDeCelular(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await _tocarTodas(tester);
  });

  testWidgets('2. rola a Para você (botão Ajuda compacta) e toca nas abas', (
    tester,
  ) async {
    _telaDeCelular(tester);
    await tester.pumpWidget(
      await _app(paraVoce: [for (var i = 0; i < 12; i++) _publicacao(i)]),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.text('Relato de pescaria número 1.'),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BotaoAjudaAssistente>(find.byType(BotaoAjudaAssistente))
          .compacto,
      isTrue,
    );

    await _tocarTodas(tester);
  });

  testWidgets('3. vai para Perfil e Alertas, volta ao Início e toca nas abas', (
    tester,
  ) async {
    _telaDeCelular(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(_destino('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(_destino('Alertas'));
    await tester.pumpAndSettle();
    await tester.tap(_destino('Início'));
    await tester.pumpAndSettle();

    await _tocarTodas(tester);
  });

  testWidgets('4. inicia e pula o tour, e o overlay não sobra por cima', (
    tester,
  ) async {
    _telaDeCelular(tester);
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    final tour = tester.element(find.byType(MainShell)).read<TourProvider>();
    tour.iniciarManual();
    await tester.pumpAndSettle();
    expect(find.byType(TourCard), findsOneWidget);

    await tour.pular();
    await tester.pumpAndSettle();
    expect(find.byType(TourCard), findsNothing);

    await _tocarTodas(tester);
  });

  testWidgets('5. publicação de autor da equipe (selo DEV) e toca nas abas', (
    tester,
  ) async {
    _telaDeCelular(tester);
    await tester.pumpWidget(
      await _app(
        paraVoce: [
          _publicacao(0, autorId: idsDevs.first),
          _publicacao(1),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BadgeEquipe), findsOneWidget);
    await _tocarTodas(tester);
  });

  testWidgets('6. login: /entrando → /home com fade e toca nas abas', (
    tester,
  ) async {
    _telaDeCelular(tester);
    // Rotas copiadas de main.dart ('/entrando' e '/home'); o login faz
    // pushReplacementNamed('/entrando').
    await tester.pumpWidget(
      await _app(
        initialRoute: '/login',
        rotas: {
          '/login': (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/entrando'),
                child: const Text('Entrar'),
              ),
            ),
          ),
          '/entrando': (context) => EntrandoPage(
            preparar: () =>
                context.read<FeedProvider>().trocarAba(AbaFeed.paraVoce),
          ),
        },
        onGenerateRoute: (settings) {
          if (settings.name != '/home') return null;
          return PageRouteBuilder<void>(
            settings: settings,
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, _, _) => MainShell(key: MainShell.shellKey),
            transitionsBuilder: (_, animacao, _, child) =>
                FadeTransition(opacity: animacao, child: child),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar'));
    // A tela de entrada tem animação em loop até sair: avança o relógio
    // em vez de esperar assentar.
    for (
      var i = 0;
      i < 40 && find.byType(EntrandoPage).evaluate().isNotEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();

    expect(find.byType(EntrandoPage), findsNothing);
    expect(find.byType(MainShell), findsOneWidget);
    await _tocarTodas(tester);
  });
}
