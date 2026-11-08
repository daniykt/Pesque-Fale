import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/data/paged_result.dart';
import 'package:pesque_fale_app/core/realtime/realtime_manager.dart';
import 'package:pesque_fale_app/core/router/rota_detalhe_publicacao.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/chat/data/conversas_repository_mock.dart';
import 'package:pesque_fale_app/features/chat/providers/badge_mensagens_provider.dart';
import 'package:pesque_fale_app/features/chat/providers/inbox_provider.dart';
import 'package:pesque_fale_app/features/feed/data/comentarios_repository.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/aba_feed.dart';
import 'package:pesque_fale_app/features/feed/domain/comentario.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/providers/feed_provider.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';
import 'package:pesque_fale_app/features/notificacoes/data/notificacoes_repository_mock.dart';
import 'package:pesque_fale_app/features/notificacoes/providers/badge_notificacoes_provider.dart';
import 'package:pesque_fale_app/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository_mock.dart';
import 'package:pesque_fale_app/features/perfil/domain/perfil_completo.dart';
import 'package:pesque_fale_app/features/perfil/presentation/perfil_de_outro_page.dart';
import 'package:pesque_fale_app/features/perfil/presentation/perfil_page.dart';
import 'package:pesque_fale_app/features/perfil/presentation/widgets/estatisticas_perfil.dart';
import 'package:pesque_fale_app/features/perfil/presentation/widgets/galeria_perfil.dart';
import 'package:pesque_fale_app/features/perfil/providers/perfil_provider.dart';
import 'package:pesque_fale_app/features/visualizacao_post/presentation/publicacao_detalhe_page.dart';
import 'package:pesque_fale_app/features/visualizacao_post/providers/publicacao_detalhe_provider.dart';

import '../support/fakes_perfil_detalhe.dart';

/// Comentários vazios que aceitam um comentário novo, como a API.
class _ComentariosRepository implements ComentariosRepository {
  final List<String> criados = [];

  @override
  Future<PagedResult<Comentario>> listar(
    String publicacaoId, {
    int pagina = 1,
    int porPagina = 20,
  }) async =>
      PagedResult(items: const [], total: 0, pagina: pagina, porPagina: 20);

  @override
  Future<Comentario> criar(String publicacaoId, String texto) async {
    criados.add(texto);
    return Comentario(
      id: 'novo-${criados.length}',
      publicacaoId: publicacaoId,
      autorId: idEu,
      autorNome: usuarioEu.nome,
      texto: texto,
      criadoEm: DateTime(2026, 1, 4),
    );
  }

  @override
  Future<void> deletar(String comentarioId) async {}
}

const _bruno = Usuario(
  id: 'bruno',
  nome: 'Bruno Pescador',
  email: 'bruno@teste.com',
  username: 'bruno',
  onboardingConcluido: true,
);

/// O perfil do Bruno, com as publicações no formato da API depois da #267
/// (autor e jaCurtiu de quem está logado).
class _PerfilDoBruno extends FakePerfilRepository {
  _PerfilDoBruno({required super.publicacoes});

  @override
  Future<PerfilCompleto> buscarPerfil(
    String id, {
    required String meuId,
  }) async {
    cargas++;
    return PerfilCompleto(usuario: _bruno, publicacoes: List.of(publicacoes));
  }
}

/// A 10.7 pelos widgets reais: a grade do perfil, a rota do detalhe do app,
/// o ⋯ e a barra de ações, numa tela de celular com o detalhe rolando.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const fotoUrl = 'https://res.cloudinary.com/demo/image/upload/v1/p.jpg';

  void telaDeCelular(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Finder item(String id) => find.descendant(
    of: find.byType(GaleriaPerfil),
    matching: find.byKey(ValueKey(id)),
  );

  Finder contadorDePublicacoes(int valor) => find.descendant(
    of: find.byType(EstatisticasPerfil),
    matching: find.text('$valor'),
  );

  Finder naLinhaDoAutor(Finder finder) => find.descendant(
    of: find.byKey(const ValueKey('detalhe-autor')),
    matching: finder,
  );

  PublicacaoDetalheProvider detalheAberto(WidgetTester tester) =>
      Provider.of<PublicacaoDetalheProvider>(
        tester.element(find.byType(PublicacaoDetalhePage)),
        listen: false,
      );

  Future<void> abrirPelaGrade(WidgetTester tester, String id) async {
    await tester.ensureVisible(item(id));
    await tester.pumpAndSettle();
    await tester.tap(item(id));
    await tester.pumpAndSettle();
    expect(find.byType(PublicacaoDetalhePage), findsOneWidget);
    expect(detalheAberto(tester).publicacao?.id, id);
  }

  /// Rola o detalhe como o usuário faz para chegar nos botões.
  Future<void> rolarDetalhe(WidgetTester tester) async {
    final rolavel = find
        .descendant(
          of: find.byType(PublicacaoDetalhePage),
          matching: find.byType(Scrollable),
        )
        .first;
    expect(
      tester.state<ScrollableState>(rolavel).position.maxScrollExtent,
      greaterThan(0),
      reason: 'o detalhe precisa rolar para o teste valer',
    );
    await tester.drag(rolavel, const Offset(0, -200));
    await tester.pumpAndSettle();
  }

  /// Segura o item e devolve os números do overlay (curtidas, comentários).
  Future<List<String>> contadoresDoToqueLongo(
    WidgetTester tester,
    String id,
  ) async {
    await tester.ensureVisible(item(id));
    await tester.pumpAndSettle();
    final gesto = await tester.startGesture(tester.getCenter(item(id)));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pump();
    final textos = tester
        .widgetList<Text>(
          find.descendant(of: item(id), matching: find.byType(Text)),
        )
        .map((t) => t.data)
        .whereType<String>()
        .where((t) => int.tryParse(t) != null)
        .toList();
    await gesto.up();
    await tester.pumpAndSettle();
    return textos;
  }

  group('no meu perfil', () {
    late PublicacoesStore store;
    late AuthProvider auth;
    late FakePerfilRepository perfilRepo;
    late FakePublicacoesRepository publicacoesRepo;
    late FakeCurtidasRepository curtidasRepo;
    late _ComentariosRepository comentariosRepo;
    late FeedProvider feed;
    late PerfilProvider perfil;

    // Com foto: no celular, o detalhe rola até as ações.
    final p1 = publicacaoDoEu(
      'p1',
      dia: 2,
      descricao: 'Tucunaré no rio Mogi',
      curtidasCount: 3,
      comentariosCount: 5,
    ).copyWith(imagemUrl: fotoUrl);
    final p2 = publicacaoDoEu(
      'p2',
      dia: 1,
      descricao: 'Tilápia no fim da tarde',
    );

    setUp(() async {
      store = PublicacoesStore();
      auth = await authLogado();
      publicacoesRepo = FakePublicacoesRepository(feed: [p1, p2]);
      perfilRepo = FakePerfilRepository(publicacoes: [p1, p2]);
      curtidasRepo = FakeCurtidasRepository();
      comentariosRepo = _ComentariosRepository();
      feed = criarFeedProvider(
        publicacoesRepo: publicacoesRepo,
        curtidasRepo: curtidasRepo,
        authProvider: auth,
        store: store,
      );
      await feed.trocarAba(AbaFeed.paraVoce);
      perfil = PerfilProvider(
        repository: perfilRepo,
        authProvider: auth,
        store: store,
      );
    });

    Future<void> montar(WidgetTester tester) async {
      telaDeCelular(tester);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<PublicacoesStore>.value(value: store),
            ChangeNotifierProvider<FeedProvider>.value(value: feed),
            ChangeNotifierProvider<PerfilProvider>.value(value: perfil),
            Provider<PublicacoesRepository>.value(value: publicacoesRepo),
            Provider<ComentariosRepository>.value(value: comentariosRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: PerfilPage()),
            // A mesma rota do main.dart.
            onGenerateRoute: rotaDetalhePublicacao,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(item('p1'), findsOneWidget);
      expect(contadorDePublicacoes(2), findsOneWidget);
    }

    /// O ⋯ da linha do autor → Excluir publicação → Excluir no diálogo.
    Future<void> excluirPeloMenu(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir publicação'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Excluir'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('excluir pelo ⋯ do detalhe: o post sai da grade e do feed e o '
        'contador cai, sem recarregar', (tester) async {
      await montar(tester);
      await abrirPelaGrade(tester, 'p1');

      await excluirPeloMenu(tester);

      // O detalhe volta sozinho ao ver a publicação removida.
      expect(find.byType(PublicacaoDetalhePage), findsNothing);
      expect(find.byType(PerfilPage), findsOneWidget);
      expect(publicacoesRepo.deletadas, ['p1']);

      expect(item('p1'), findsNothing);
      expect(item('p2'), findsOneWidget);
      expect(contadorDePublicacoes(1), findsOneWidget);
      expect(contadorDePublicacoes(2), findsNothing);
      expect(feed.paraVoce.map((p) => p.id), ['p2']);
      expect(perfilRepo.cargas, 1, reason: 'o perfil não pode ter recarregado');
      expect(tester.takeException(), isNull);
    });

    testWidgets('excluir pelo ⋯ do detalhe avisa Publicação excluída', (
      tester,
    ) async {
      await montar(tester);
      await abrirPelaGrade(tester, 'p1');

      await excluirPeloMenu(tester);

      expect(find.byType(PublicacaoDetalhePage), findsNothing);
      expect(find.text('Publicação excluída.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'curtir e comentar pelos botões do detalhe, com a tela rolando: '
      'a grade e o feed mostram os contadores novos',
      (tester) async {
        await montar(tester);
        expect(await contadoresDoToqueLongo(tester, 'p1'), ['3', '5']);

        await abrirPelaGrade(tester, 'p1');
        await rolarDetalhe(tester);

        await tester.ensureVisible(find.text('Curtir'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Curtir'));
        await tester.pumpAndSettle();
        expect(find.text('Curtido'), findsOneWidget);

        await tester.tap(find.text('Comentar'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Que beleza!');
        await tester.pump();
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();
        expect(curtidasRepo.curtidas, ['p1']);
        expect(comentariosRepo.criados, ['Que beleza!']);

        // Volta pela seta da barra, como o usuário.
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(PublicacaoDetalhePage), findsNothing);

        expect(await contadoresDoToqueLongo(tester, 'p1'), ['4', '6']);
        expect(await contadoresDoToqueLongo(tester, 'p2'), ['0', '0']);

        final noFeed = feed.paraVoce.firstWhere((p) => p.id == 'p1');
        expect(noFeed.curtidasCount, 4);
        expect(noFeed.jaCurtiu, isTrue);
        expect(noFeed.comentariosCount, 6);
        expect(
          perfilRepo.cargas,
          1,
          reason: 'o perfil não pode ter recarregado',
        );
        expect(publicacoesRepo.buscasPorId, 0);
        expect(tester.takeException(), isNull);
      },
    );
  });

  testWidgets(
    'no perfil de outra pessoa, tocar no item abre a publicação certa '
    'com o autor e a minha curtida, sem buscar na API',
    (tester) async {
      telaDeCelular(tester);
      final store = PublicacoesStore();
      final auth = await authLogado();
      // Formato da API depois da #267: autor e jaCurtiu de quem está logado.
      Publicacao doBruno(
        String id, {
        required bool jaCurtiu,
        int curtidas = 0,
      }) => Publicacao(
        id: id,
        autorId: _bruno.id,
        autorNome: _bruno.nome,
        autorUsername: _bruno.username,
        descricao: 'Pescaria $id',
        imagemUrl: fotoUrl,
        curtidasCount: curtidas,
        jaCurtiu: jaCurtiu,
        criadoEm: DateTime(2026, 1, 1),
        atualizadoEm: DateTime(2026, 1, 1),
      );
      final perfilRepo = _PerfilDoBruno(
        publicacoes: [
          doBruno('b1', jaCurtiu: false),
          doBruno('b2', jaCurtiu: true, curtidas: 7),
        ],
      );
      final publicacoesRepo = FakePublicacoesRepository(feed: const []);
      final feed = criarFeedProvider(
        publicacoesRepo: publicacoesRepo,
        curtidasRepo: FakeCurtidasRepository(),
        authProvider: auth,
        store: store,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<PublicacoesStore>.value(value: store),
            ChangeNotifierProvider<FeedProvider>.value(value: feed),
            ChangeNotifierProvider<PerfilProvider>(
              create: (_) => PerfilProvider(
                repository: perfilRepo,
                authProvider: auth,
                store: store,
              ),
            ),
            ChangeNotifierProvider<BadgeNotificacoesProvider>(
              create: (_) => BadgeNotificacoesProvider(
                notificacoes: NotificacoesProvider(
                  repository: NotificacoesRepositoryMock(),
                  perfilRepository: PerfilRepositoryMock(),
                  realtime: RealtimeManager(),
                ),
              ),
            ),
            ChangeNotifierProvider<BadgeMensagensProvider>(
              create: (_) => BadgeMensagensProvider(
                inbox: InboxProvider(
                  repository: ConversasRepositoryMock(),
                  realtime: RealtimeManager(),
                ),
              ),
            ),
            Provider<PublicacoesRepository>.value(value: publicacoesRepo),
            Provider<ComentariosRepository>.value(
              value: _ComentariosRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const PerfilDeOutroPage(usuarioId: 'bruno'),
            // A mesma rota do main.dart.
            onGenerateRoute: rotaDetalhePublicacao,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(item('b1'), findsOneWidget);
      expect(item('b2'), findsOneWidget);

      await abrirPelaGrade(tester, 'b2');

      expect(find.text('Pescaria b2'), findsOneWidget);
      expect(naLinhaDoAutor(find.text('Bruno Pescador')), findsOneWidget);
      expect(naLinhaDoAutor(find.textContaining('@bruno · ')), findsOneWidget);
      await tester.ensureVisible(find.text('Curtido'));
      await tester.pumpAndSettle();
      expect(find.text('Curtido'), findsOneWidget);
      expect(find.text('7 curtidas'), findsOneWidget);
      // O ⋯ da publicação de outra pessoa não oferece excluir.
      await tester.tap(find.byTooltip('Mais opções'));
      await tester.pumpAndSettle();
      expect(find.text('Excluir publicação'), findsNothing);

      expect(publicacoesRepo.buscasPorId, 0);
      expect(perfilRepo.cargas, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
