import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:pesque_fale_app/core/data/paged_result.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository_mock.dart';
import 'package:pesque_fale_app/features/auth/data/token_storage.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/presentation/entrando/entrando_page.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
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
import 'package:pesque_fale_app/features/feed/domain/dados_evento.dart';
import 'package:pesque_fale_app/features/feed/domain/evento.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/presentation/feed_page.dart';
import 'package:pesque_fale_app/features/feed/presentation/widgets/novas_publicacoes_button.dart';
import 'package:pesque_fale_app/features/feed/providers/feed_provider.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_repository.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/filtros_locais.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/ponto.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/tipo_ponto.dart';

import '../../chat/support/fake_realtime_manager.dart';

// Fakes locais sem nenhuma URL de imagem — os testes aqui verificam
// navegação entre abas e conteúdo textual, não carregamento de imagem de
// rede (o Image.network real é coberto visualmente, não em teste headless).

class _FakePublicacoesRepository implements PublicacoesRepository {
  final List<Publicacao> todas = [
    Publicacao(
      id: 'pub-0',
      autorId: 'autor-0',
      autorNome: 'Pescador Zero',
      descricao: 'Relato de pescaria número 1.',
      comentariosCount: 0,
      criadoEm: DateTime(2026, 1, 1),
      atualizadoEm: DateTime(2026, 1, 1),
    ),
  ];

  /// O que o feed Seguindo devolve, mais recente primeiro (página única).
  final List<Publicacao> seguindoItens = [];
  int chamadas = 0;
  Duration atraso = Duration.zero;
  int? total;
  bool falharProximasPaginas = false;

  @override
  Future<PagedResult<Publicacao>> listar({
    int pagina = 1,
    int porPagina = 20,
    bool seguindo = false,
  }) async {
    chamadas++;
    if (atraso > Duration.zero) await Future<void>.delayed(atraso);
    if (pagina > 1 && falharProximasPaginas) throw Exception('sem rede');
    final itens = seguindo ? List.of(seguindoItens) : todas;
    return PagedResult(
      items: pagina > 1 ? const [] : itens,
      total: total ?? itens.length,
      pagina: pagina,
      porPagina: porPagina,
    );
  }

  @override
  Future<Publicacao> buscarPorId(String id) async =>
      todas.firstWhere((p) => p.id == id);

  @override
  Future<void> deletar(String id) async => todas.removeWhere((p) => p.id == id);

  @override
  Future<Publicacao> criar({
    String? descricao,
    String? imagemUrl,
    String? localTexto,
    double? avaliacaoNota,
    String? pontoId,
    List<String> tags = const [],
  }) async => throw UnimplementedError();
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
  }) async {
    return const PagedResult(items: [], total: 0, pagina: 1, porPagina: 20);
  }

  @override
  Future<Comentario> criar(String publicacaoId, String texto) async {
    return Comentario(
      id: 'novo',
      publicacaoId: publicacaoId,
      autorId: 'u1',
      autorNome: 'Ana',
      texto: texto,
      criadoEm: DateTime.now(),
    );
  }

  @override
  Future<void> deletar(String comentarioId) async {}
}

class _FakeEventosRepository implements EventosRepository {
  int chamadas = 0;

  @override
  Future<List<Evento>> listar({bool futuros = true, int limite = 10}) async {
    chamadas++;
    return [
      Evento(
        id: 'evento-0',
        titulo: 'Torneio de Pesca de Verão',
        organizadorId: 'autor-0',
        organizadorNome: 'Clube de Pesca',
        dataInicio: DateTime.now().add(const Duration(days: 3)),
        criadoEm: DateTime.now(),
      ),
    ];
  }

  @override
  Future<Evento> buscarPorId(String id) => throw UnimplementedError();

  @override
  Future<Evento> criar(DadosEvento dados) => throw UnimplementedError();

  @override
  Future<Evento> editar(String id, DadosEvento dados) =>
      throw UnimplementedError();

  @override
  Future<void> excluir(String id) => throw UnimplementedError();
}

class _FakePontosRepository implements PontosRepository {
  int chamadas = 0;

  @override
  Future<List<Ponto>> buscar({
    required FiltrosLocais filtros,
    double? lat,
    double? lng,
    bool incluirDistancia = false,
    String? ordem,
  }) async {
    chamadas++;
    return [
      const Ponto(
        id: 'ponto-0',
        nome: 'Rio das Pratas',
        latitude: -21.6,
        longitude: -48.3,
        cidade: 'Matão',
        estado: 'SP',
        tipo: TipoPonto.rio,
        avgNota: 4.5,
        totalAvaliacoes: 10,
        criadoPor: 'autor-0',
      ),
    ];
  }

  @override
  Future<Ponto> buscarPorId(String id) async => throw UnimplementedError();
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) async => throw UnimplementedError();

  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async {
    return const AuthResult(
      accessToken: 'token',
      usuario: Usuario(
        id: 'eu',
        nome: 'Ana',
        email: 'ana@teste.com',
        onboardingConcluido: true,
      ),
    );
  }

  @override
  Future<void> logout() async {}
}

Publicacao _publicacaoSeguindo(String id) {
  return Publicacao(
    id: id,
    autorId: 'autor-seguido',
    autorNome: 'Pescador Seguido',
    descricao: 'Publicação $id do feed Seguindo.',
    criadoEm: DateTime(2026, 1, 1),
    atualizadoEm: DateTime(2026, 1, 1),
  );
}

class _FakeClimaRepository implements ClimaRepository {
  int chamadas = 0;

  @override
  Future<Clima> buscarAtual({
    required double latitude,
    required double longitude,
  }) async {
    chamadas++;
    return const Clima(
      temperatura: 21.6,
      umidade: 83,
      ventoKmh: 7.2,
      condicao: CondicaoClima.chuva,
    );
  }
}

class _FakeLocalizacao implements LocalizacaoService {
  @override
  Future<ResultadoLocalizacao> obter({required bool pedirPermissao}) async =>
      const LocalizacaoObtida(latitude: -21.6, longitude: -48.36);

  @override
  Future<void> abrirConfiguracoes(MotivoSemLocalizacao motivo) async {}
}

Widget _harness({
  required AuthProvider authProvider,
  _FakePublicacoesRepository? publicacoes,
  FakeRealtimeManager? realtime,
  _FakeEventosRepository? eventos,
  _FakePontosRepository? pontos,
  ThemeData? tema,
  _FakeClimaRepository? clima,
}) {
  final publicacoesRepo = publicacoes ?? _FakePublicacoesRepository();
  final realtimeManager = realtime ?? FakeRealtimeManager();
  final curtidasRepo = _FakeCurtidasRepository();
  final comentariosRepo = _FakeComentariosRepository();
  final eventosRepo = eventos ?? _FakeEventosRepository();
  final pontosRepo = pontos ?? _FakePontosRepository();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      Provider<PublicacoesRepository>.value(value: publicacoesRepo),
      Provider<CurtidasRepository>.value(value: curtidasRepo),
      Provider<ComentariosRepository>.value(value: comentariosRepo),
      Provider<EventosRepository>.value(value: eventosRepo),
      Provider<PontosRepository>.value(value: pontosRepo),
      ChangeNotifierProvider<ClimaProvider>(
        create: (_) => ClimaProvider(
          repository: clima ?? _FakeClimaRepository(),
          localizacao: _FakeLocalizacao(),
        ),
      ),
      ChangeNotifierProxyProvider<AuthProvider, FeedProvider>(
        create: (context) => FeedProvider(
          publicacoesRepo: publicacoesRepo,
          curtidasRepo: curtidasRepo,
          eventosRepo: eventosRepo,
          pontosRepo: pontosRepo,
          authProvider: authProvider,
          realtime: realtimeManager,
          store: PublicacoesStore(),
        ),
        update: (context, auth, previous) => previous!..reagirAuth(auth),
      ),
    ],
    child: MaterialApp(
      theme: tema ?? AppTheme.light,
      routes: {'/login': (_) => const Scaffold(body: Text('Tela de login'))},
      home: const FeedPage(),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('carrega a aba Para você e mostra publicações do repositório', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
    );

    await tester.pumpWidget(_harness(authProvider: authProvider));
    await tester.pumpAndSettle();

    expect(find.text('Para você'), findsOneWidget);
    expect(find.text('Relato de pescaria número 1.'), findsOneWidget);
  });

  testWidgets('aba Seguindo sem login mostra CTA de login', (tester) async {
    final authProvider = AuthProvider(
      repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
    );

    await tester.pumpWidget(_harness(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Seguindo'));
    await tester.pumpAndSettle();

    expect(find.text('Faça login pra ver seu feed'), findsOneWidget);
  });

  testWidgets('aba Eventos mostra o carrossel de eventos do repositório', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
    );

    await tester.pumpWidget(_harness(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eventos'));
    await tester.pumpAndSettle();

    expect(find.text('Próximos eventos'), findsOneWidget);
    expect(find.text('Torneio de Pesca de Verão'), findsOneWidget);
  });

  testWidgets('aba Locais mostra o carrossel de locais mais bem avaliados', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
    );

    await tester.pumpWidget(_harness(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Locais'));
    await tester.pumpAndSettle();

    expect(find.text('Locais mais bem avaliados'), findsOneWidget);
    expect(find.text('Rio das Pratas'), findsOneWidget);
  });

  testWidgets('puxar para atualizar na aba Eventos busca de novo', (
    tester,
  ) async {
    final eventos = _FakeEventosRepository();
    await tester.pumpWidget(
      _harness(
        authProvider: AuthProvider(
          repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
        ),
        eventos: eventos,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eventos'));
    await tester.pumpAndSettle();
    expect(eventos.chamadas, 1);

    await tester.fling(
      find.text('Próximos eventos'),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(eventos.chamadas, 2);
  });

  testWidgets('puxar para atualizar na aba Locais busca de novo', (
    tester,
  ) async {
    final pontos = _FakePontosRepository();
    await tester.pumpWidget(
      _harness(
        authProvider: AuthProvider(
          repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
        ),
        pontos: pontos,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Locais'));
    await tester.pumpAndSettle();
    expect(pontos.chamadas, 1);

    await tester.fling(
      find.text('Locais mais bem avaliados'),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(pontos.chamadas, 2);
  });

  testWidgets('login seguido do /entrando busca a Para você uma vez só', (
    tester,
  ) async {
    final publicacoes = _FakePublicacoesRepository()
      ..atraso = const Duration(seconds: 1);
    final authProvider = AuthProvider(repository: _FakeAuthRepository());
    final eventos = _FakeEventosRepository();
    final pontos = _FakePontosRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProxyProvider<AuthProvider, FeedProvider>(
            lazy: false,
            create: (_) => FeedProvider(
              publicacoesRepo: publicacoes,
              curtidasRepo: _FakeCurtidasRepository(),
              eventosRepo: eventos,
              pontosRepo: pontos,
              authProvider: authProvider,
              realtime: FakeRealtimeManager(),
              store: PublicacoesStore(),
            ),
            update: (_, auth, previous) => previous!..reagirAuth(auth),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          routes: {
            '/': (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  await context.read<AuthProvider>().login(
                    email: 'ana@teste.com',
                    senha: '123456',
                  );
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/entrando');
                  }
                },
                child: const Text('Entrar'),
              ),
            ),
            '/entrando': (context) => EntrandoPage(
              duracaoMinima: Duration.zero,
              preparar: () =>
                  context.read<FeedProvider>().trocarAba(AbaFeed.paraVoce),
            ),
            '/home': (_) => const Scaffold(body: Text('Home')),
          },
        ),
      ),
    );

    await tester.tap(find.text('Entrar'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(EntrandoPage), findsOneWidget);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      find.text('Home'),
      findsNothing,
      reason: 'o /entrando espera a Para você carregar',
    );

    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(publicacoes.chamadas, 1);
    final feed = tester.element(find.text('Home')).read<FeedProvider>();
    expect(feed.estadoDe(AbaFeed.paraVoce).status, StatusAba.sucesso);
  });

  for (final (nomeTema, criarTema) in [
    ('claro', () => AppTheme.light),
    ('escuro', () => AppTheme.dark),
  ]) {
    testWidgets(
      'erro ao carregar mais mantém os cards e mostra Tentar de novo no '
      'rodapé (tema $nomeTema)',
      (tester) async {
        final tema = criarTema();
        final publicacoes = _FakePublicacoesRepository()
          ..total = 40
          ..falharProximasPaginas = true;
        await tester.pumpWidget(
          _harness(
            authProvider: AuthProvider(
              repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
            ),
            publicacoes: publicacoes,
            tema: tema,
          ),
        );
        await tester.pumpAndSettle();
        final feed = tester.element(find.byType(FeedPage)).read<FeedProvider>();

        await feed.carregarMais();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Relato de pescaria número 1.'), findsOneWidget);
        expect(find.text('Tentar novamente'), findsNothing);
        expect(
          find.text('Não foi possível carregar mais publicações.'),
          findsOneWidget,
        );
        final botao = tester.widget<ButtonStyleButton>(
          find.ancestor(
            of: find.text('Tentar de novo'),
            matching: find.byWidgetPredicate((w) => w is OutlinedButton),
          ),
        );
        expect(
          botao.style!.foregroundColor!.resolve(const {}),
          tema.extension<AppColors>()!.primaryAccent,
        );
        final antes = publicacoes.chamadas;

        publicacoes.falharProximasPaginas = false;
        await tester.ensureVisible(find.text('Tentar de novo'));
        await tester.tap(find.text('Tentar de novo'));
        await tester.pumpAndSettle();

        expect(publicacoes.chamadas, antes + 1);
        expect(find.text('Tentar de novo'), findsNothing);
        expect(find.text('Relato de pescaria número 1.'), findsOneWidget);
      },
    );
  }

  testWidgets('cada card do feed tem a chave do id da publicação', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        authProvider: AuthProvider(
          repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pub-0')), findsOneWidget);
  });

  testWidgets('excluir um card não recria os cards seguintes', (tester) async {
    final publicacoes = _FakePublicacoesRepository();
    publicacoes.todas.add(
      Publicacao(
        id: 'pub-1',
        autorId: 'autor-1',
        autorNome: 'Pescador Um',
        descricao: 'Relato de pescaria número 2.',
        criadoEm: DateTime(2026, 1, 1),
        atualizadoEm: DateTime(2026, 1, 1),
      ),
    );
    await tester.pumpWidget(
      _harness(
        authProvider: AuthProvider(
          repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
        ),
        publicacoes: publicacoes,
      ),
    );
    await tester.pumpAndSettle();
    final antes = tester.element(find.byKey(const ValueKey('pub-1')));

    tester
        .element(find.byType(FeedPage))
        .read<FeedProvider>()
        .removerPublicacao('pub-0');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pub-0')), findsNothing);
    expect(
      identical(tester.element(find.byKey(const ValueKey('pub-1'))), antes),
      isTrue,
    );
  });

  Future<_FakeClimaRepository> abrirDicas(WidgetTester tester) async {
    final clima = _FakeClimaRepository();
    await tester.pumpWidget(
      _harness(
        authProvider: AuthProvider(
          repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
        ),
        clima: clima,
      ),
    );
    await tester.pumpAndSettle();
    expect(clima.chamadas, 0, reason: 'a aba Dicas ainda não foi aberta');
    await tester.tap(find.text('Dicas'));
    await tester.pumpAndSettle();
    return clima;
  }

  testWidgets('aba Dicas busca o clima ao abrir e mostra o clima real', (
    tester,
  ) async {
    final clima = await abrirDicas(tester);

    expect(clima.chamadas, 1);
    expect(find.text('Clima agora'), findsOneWidget);
    expect(find.text('22°C'), findsOneWidget);
    expect(find.text('Chuva'), findsOneWidget);
    expect(find.text('Vento: 7 km/h'), findsOneWidget);
    expect(find.text('Umidade: 83%'), findsOneWidget);
    expect(find.text('28°C'), findsNothing);
    expect(find.textContaining('Melhor período'), findsNothing);
    expect(find.textContaining('Condições ótimas'), findsNothing);
    expect(find.text('Dica do dia'), findsOneWidget);
  });

  testWidgets('sair e voltar logo para a aba Dicas reaproveita o clima', (
    tester,
  ) async {
    final clima = await abrirDicas(tester);

    await tester.tap(find.text('Eventos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dicas'));
    await tester.pumpAndSettle();

    expect(clima.chamadas, 1);
    expect(find.text('22°C'), findsOneWidget);
  });

  testWidgets('puxar para atualizar na aba Dicas busca o clima de novo', (
    tester,
  ) async {
    final clima = await abrirDicas(tester);

    await tester.fling(find.text('Clima agora'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(clima.chamadas, 2);
  });

  testWidgets('abrir o menu de comentários mostra o estado vazio', (
    tester,
  ) async {
    final authProvider = AuthProvider(
      repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
    );

    await tester.pumpWidget(_harness(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('0 comentários'));
    await tester.pumpAndSettle();

    expect(find.text('Comentários'), findsOneWidget);
    expect(
      find.text('Nenhum comentário ainda. Seja o primeiro!'),
      findsOneWidget,
    );
  });

  group('chip de novas publicações na aba Seguindo', () {
    late _FakePublicacoesRepository publicacoesRepo;
    late FakeRealtimeManager realtime;

    /// Monta logado, com 10 publicações no Seguindo, e abre a aba.
    Future<void> abrirSeguindo(WidgetTester tester) async {
      final authProvider = AuthProvider(repository: _FakeAuthRepository());
      await authProvider.login(email: 'ana@teste.com', senha: '123456');
      publicacoesRepo = _FakePublicacoesRepository();
      publicacoesRepo.seguindoItens.addAll(
        List.generate(10, (i) => _publicacaoSeguindo('s$i')),
      );
      realtime = FakeRealtimeManager();

      await tester.pumpWidget(
        _harness(
          authProvider: authProvider,
          publicacoes: publicacoesRepo,
          realtime: realtime,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seguindo'));
      await tester.pumpAndSettle();
    }

    /// O autor seguido publica: entra no servidor e o evento chega.
    Future<void> chegaPublicacao(WidgetTester tester, String id) async {
      publicacoesRepo.seguindoItens.insert(0, _publicacaoSeguindo(id));
      realtime.emitir('nova_publicacao_feed', {
        'publicacaoId': id,
        'autorId': 'autor-seguido',
        'timestamp': '2026-10-27T12:00:00.000Z',
      });
      await tester.pumpAndSettle();
    }

    // A barra de abas também é Scrollable; mira o da lista do feed.
    double offsetDaLista(WidgetTester tester) => tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;

    testWidgets('rolado pra baixo: chip aparece e acumula a contagem', (
      tester,
    ) async {
      await abrirSeguindo(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(offsetDaLista(tester), greaterThan(100));

      await chegaPublicacao(tester, 'nova-1');
      expect(find.text('1 nova publicação'), findsOneWidget);
      expect(find.text('Publicação nova-1 do feed Seguindo.'), findsNothing);

      await chegaPublicacao(tester, 'nova-2');
      expect(find.text('2 novas publicações'), findsOneWidget);
    });

    testWidgets('clique no chip rola pro topo, aplica e o chip some', (
      tester,
    ) async {
      await abrirSeguindo(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await chegaPublicacao(tester, 'nova-1');

      await tester.tap(find.byType(NovasPublicacoesButton));
      await tester.pumpAndSettle();

      expect(find.byType(NovasPublicacoesButton), findsNothing);
      expect(offsetDaLista(tester), 0);
      expect(find.text('Publicação nova-1 do feed Seguindo.'), findsOneWidget);
    });

    testWidgets('no topo: publicação entra direto, sem chip', (tester) async {
      await abrirSeguindo(tester);

      await chegaPublicacao(tester, 'nova-1');

      expect(find.byType(NovasPublicacoesButton), findsNothing);
      expect(find.text('Publicação nova-1 do feed Seguindo.'), findsOneWidget);
    });
  });

  group('chip de novas publicações na aba Para você', () {
    late _FakePublicacoesRepository publicacoesRepo;
    late FakeRealtimeManager realtime;

    Publicacao publicacaoParaVoce(String id) => Publicacao(
      id: id,
      autorId: 'autor-qualquer',
      autorNome: 'Pescador Qualquer',
      descricao: 'Publicação $id da Para você.',
      criadoEm: DateTime(2026, 1, 1),
      atualizadoEm: DateTime(2026, 1, 1),
    );

    Future<void> abrirParaVoce(WidgetTester tester) async {
      final authProvider = AuthProvider(repository: _FakeAuthRepository());
      await authProvider.login(email: 'ana@teste.com', senha: '123456');
      publicacoesRepo = _FakePublicacoesRepository();
      publicacoesRepo.todas
        ..clear()
        ..addAll(List.generate(10, (i) => publicacaoParaVoce('pv$i')));
      realtime = FakeRealtimeManager();

      await tester.pumpWidget(
        _harness(
          authProvider: authProvider,
          publicacoes: publicacoesRepo,
          realtime: realtime,
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> chegaPublicacao(WidgetTester tester, String id) async {
      publicacoesRepo.todas.insert(0, publicacaoParaVoce(id));
      realtime.emitir('publicacao_criada', {
        'publicacaoId': id,
        'autorId': 'autor-qualquer',
        'timestamp': '2026-11-06T12:00:00.000Z',
      });
      await tester.pumpAndSettle();
    }

    double offsetDaLista(WidgetTester tester) => tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;

    testWidgets('rolado pra baixo: chip aparece e acumula a contagem', (
      tester,
    ) async {
      await abrirParaVoce(tester);
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(offsetDaLista(tester), greaterThan(100));

      await chegaPublicacao(tester, 'nova-1');
      expect(find.text('1 nova publicação'), findsOneWidget);
      expect(find.text('Publicação nova-1 da Para você.'), findsNothing);

      await chegaPublicacao(tester, 'nova-2');
      expect(find.text('2 novas publicações'), findsOneWidget);
    });

    testWidgets('clique no chip rola pro topo, aplica e o chip some', (
      tester,
    ) async {
      await abrirParaVoce(tester);
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      await chegaPublicacao(tester, 'nova-1');

      await tester.tap(find.byType(NovasPublicacoesButton));
      await tester.pumpAndSettle();

      expect(find.byType(NovasPublicacoesButton), findsNothing);
      expect(offsetDaLista(tester), 0);
      expect(find.text('Publicação nova-1 da Para você.'), findsOneWidget);
    });

    testWidgets('no topo: publicação entra direto, sem chip', (tester) async {
      await abrirParaVoce(tester);

      await chegaPublicacao(tester, 'nova-1');

      expect(find.byType(NovasPublicacoesButton), findsNothing);
      expect(find.text('Publicação nova-1 da Para você.'), findsOneWidget);
    });

    testWidgets('evento só da Seguindo não mostra chip na Para você', (
      tester,
    ) async {
      await abrirParaVoce(tester);
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      realtime.emitir('nova_publicacao_feed', {
        'publicacaoId': 'so-seguindo',
        'autorId': 'autor-seguido',
        'timestamp': '2026-11-06T12:00:00.000Z',
      });
      await tester.pumpAndSettle();

      expect(find.byType(NovasPublicacoesButton), findsNothing);
    });
  });
}
