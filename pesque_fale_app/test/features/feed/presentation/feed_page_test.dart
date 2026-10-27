import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:pesque_fale_app/core/data/paged_result.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository_mock.dart';
import 'package:pesque_fale_app/features/auth/data/token_storage.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/feed/data/comentarios_repository.dart';
import 'package:pesque_fale_app/features/feed/data/curtidas_repository.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_repository.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/comentario.dart';
import 'package:pesque_fale_app/features/feed/domain/evento.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/presentation/feed_page.dart';
import 'package:pesque_fale_app/features/feed/presentation/widgets/novas_publicacoes_button.dart';
import 'package:pesque_fale_app/features/feed/providers/feed_provider.dart';
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

  @override
  Future<PagedResult<Publicacao>> listar({
    int pagina = 1,
    int porPagina = 20,
    bool seguindo = false,
  }) async {
    final itens = seguindo ? List.of(seguindoItens) : todas;
    return PagedResult(
      items: itens,
      total: itens.length,
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
  @override
  Future<List<Evento>> listar({bool futuros = true, int limite = 10}) async {
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
}

class _FakePontosRepository implements PontosRepository {
  @override
  Future<List<Ponto>> buscar({
    required FiltrosLocais filtros,
    double? lat,
    double? lng,
    bool incluirDistancia = false,
    String? ordem,
  }) async {
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

Widget _harness({
  required AuthProvider authProvider,
  _FakePublicacoesRepository? publicacoes,
  FakeRealtimeManager? realtime,
}) {
  final publicacoesRepo = publicacoes ?? _FakePublicacoesRepository();
  final realtimeManager = realtime ?? FakeRealtimeManager();
  final curtidasRepo = _FakeCurtidasRepository();
  final comentariosRepo = _FakeComentariosRepository();
  final eventosRepo = _FakeEventosRepository();
  final pontosRepo = _FakePontosRepository();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      Provider<PublicacoesRepository>.value(value: publicacoesRepo),
      Provider<CurtidasRepository>.value(value: curtidasRepo),
      Provider<ComentariosRepository>.value(value: comentariosRepo),
      Provider<EventosRepository>.value(value: eventosRepo),
      Provider<PontosRepository>.value(value: pontosRepo),
      ChangeNotifierProxyProvider<AuthProvider, FeedProvider>(
        create: (context) => FeedProvider(
          publicacoesRepo: publicacoesRepo,
          curtidasRepo: curtidasRepo,
          eventosRepo: eventosRepo,
          pontosRepo: pontosRepo,
          authProvider: authProvider,
          realtime: realtimeManager,
        ),
        update: (context, auth, previous) => previous!..reagirAuth(auth),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
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

  testWidgets('aba Dicas mostra clima e dica do dia hardcoded', (tester) async {
    final authProvider = AuthProvider(
      repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
    );

    await tester.pumpWidget(_harness(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dicas'));
    await tester.pumpAndSettle();

    expect(find.text('Clima Agora'), findsOneWidget);
    expect(find.text('Dica do dia'), findsOneWidget);
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
}
