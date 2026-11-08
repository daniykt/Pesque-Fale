import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/data/paged_result.dart';
import 'package:pesque_fale_app/core/router/rota_detalhe_publicacao.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/feed/data/comentarios_repository.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/aba_feed.dart';
import 'package:pesque_fale_app/features/feed/domain/comentario.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/providers/feed_provider.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';
import 'package:pesque_fale_app/features/visualizacao_post/presentation/publicacao_detalhe_page.dart';

import '../../perfil/support/fakes_perfil_detalhe.dart';

/// Notificação abre o detalhe só com o id: aqui o buscarPorId responde.
class _PublicacoesRepository extends FakePublicacoesRepository {
  _PublicacoesRepository({required super.feed, required this.porId});

  final Publicacao porId;

  @override
  Future<Publicacao> buscarPorId(String id) async {
    buscasPorId++;
    return porId;
  }
}

/// Um comentário do usuário logado, que pode ser apagado, seguido de
/// [outros] comentários de outra pessoa. Pagina como a API e registra as
/// páginas pedidas.
class _ComentariosRepository implements ComentariosRepository {
  _ComentariosRepository({this.outros = 0});

  final int outros;
  final List<String> deletados = [];
  final List<int> paginasPedidas = [];
  final List<String> criados = [];

  final _meu = Comentario(
    id: 'c1',
    publicacaoId: 'p1',
    autorId: idEu,
    autorNome: usuarioEu.nome,
    texto: 'Que peixe bonito!',
    criadoEm: DateTime(2026, 1, 3),
  );

  List<Comentario> get _todos => [
    if (!deletados.contains('c1')) _meu,
    for (var i = 2; i <= outros + 1; i++)
      Comentario(
        id: 'c$i',
        publicacaoId: 'p1',
        autorId: 'outro',
        autorNome: 'Outro Pescador',
        texto: 'Comentário $i',
        criadoEm: DateTime(2026, 1, 3),
      ),
  ];

  @override
  Future<PagedResult<Comentario>> listar(
    String publicacaoId, {
    int pagina = 1,
    int porPagina = 20,
  }) async {
    paginasPedidas.add(pagina);
    final todos = _todos;
    final inicio = (pagina - 1) * porPagina;
    final fim = (inicio + porPagina).clamp(0, todos.length);
    return PagedResult(
      items: inicio >= todos.length ? const [] : todos.sublist(inicio, fim),
      total: todos.length,
      pagina: pagina,
      porPagina: porPagina,
    );
  }

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
  Future<void> deletar(String comentarioId) async =>
      deletados.add(comentarioId);
}

/// De onde o detalhe é aberto no app e o argumento que a rota recebe.
enum _Origem { feed, perfil, notificacao }

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  final p1 = publicacaoDoEu(
    'p1',
    descricao: 'Tucunaré no rio Mogi',
    curtidasCount: 3,
    comentariosCount: 1,
  );

  late PublicacoesStore store;
  late AuthProvider auth;
  late FakeCurtidasRepository curtidasRepo;
  late _ComentariosRepository comentariosRepo;
  late _PublicacoesRepository publicacoesRepo;
  late FeedProvider feed;

  Future<void> preparar(
    _Origem origem, {
    Publicacao? publicacao,
    int outrosComentarios = 0,
  }) async {
    final post = publicacao ?? p1;
    store = PublicacoesStore();
    auth = await authLogado();
    curtidasRepo = FakeCurtidasRepository();
    comentariosRepo = _ComentariosRepository(outros: outrosComentarios);
    // Só o feed carrega o p1 nas listas dele. Pelo perfil e pela
    // notificação, o post não está no feed.
    publicacoesRepo = _PublicacoesRepository(
      feed: origem == _Origem.feed ? [post] : const [],
      porId: post,
    );
    feed = criarFeedProvider(
      publicacoesRepo: publicacoesRepo,
      curtidasRepo: curtidasRepo,
      authProvider: auth,
      store: store,
    );
    await feed.trocarAba(AbaFeed.paraVoce);
    if (origem == _Origem.perfil) store.inserirSeAusente([post]);
  }

  Future<void> abrirDetalhe(WidgetTester tester, _Origem origem) async {
    final Object argumento = switch (origem) {
      _Origem.feed => feed.paraVoce.single,
      _Origem.perfil => store.porId('p1')!,
      _Origem.notificacao => 'p1',
    };

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<PublicacoesStore>.value(value: store),
          ChangeNotifierProvider<FeedProvider>.value(value: feed),
          Provider<PublicacoesRepository>.value(value: publicacoesRepo),
          Provider<ComentariosRepository>.value(value: comentariosRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/publicacao/detalhe',
                  arguments: argumento,
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
          // A mesma rota do main.dart.
          onGenerateRoute: rotaDetalhePublicacao,
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(PublicacaoDetalhePage), findsOneWidget);
    expect(find.text('Tucunaré no rio Mogi'), findsOneWidget);
  }

  for (final origem in _Origem.values) {
    testWidgets(
      'tocar em Curtir no detalhe curte (aberto pelo ${origem.name})',
      (tester) async {
        await preparar(origem);
        await abrirDetalhe(tester, origem);
        expect(find.text('3 curtidas'), findsOneWidget);

        await tester.ensureVisible(find.text('Curtir'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Curtir'));
        await tester.pumpAndSettle();

        expect(curtidasRepo.curtidas, ['p1']);
        expect(find.text('Curtido'), findsOneWidget);
        expect(find.text('4 curtidas'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('tocar na lixeira do meu comentário apaga '
        '(aberto pelo ${origem.name})', (tester) async {
      await preparar(origem);
      await abrirDetalhe(tester, origem);
      expect(find.text('Que peixe bonito!'), findsOneWidget);
      expect(find.text('1 comentário'), findsOneWidget);

      await tester.ensureVisible(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Excluir comentário'), findsOneWidget);
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(comentariosRepo.deletados, ['c1']);
      expect(find.text('Que peixe bonito!'), findsNothing);
      expect(find.text('0 comentários'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  // No aparelho o detalhe rola: a foto (4:5 da largura) empurra as ações para
  // baixo da dobra. Cada ScrollNotification passa pelo "carregar mais" dos
  // comentários, que foi o que quebrou (#318). Na tela de teste padrão
  // (800x600, sem foto) nada rola e o problema não aparece.
  group('com o detalhe rolando, numa tela de celular', () {
    final comFoto = p1.copyWith(
      imagemUrl: 'https://res.cloudinary.com/demo/image/upload/tucunare.jpg',
    );

    void telaDeCelular(WidgetTester tester) {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    Finder rolavelDoDetalhe() => find
        .descendant(
          of: find.byType(PublicacaoDetalhePage),
          matching: find.byType(SingleChildScrollView),
        )
        .first;

    ScrollPosition posicao(WidgetTester tester) => tester
        .state<ScrollableState>(
          find
              .descendant(
                of: rolavelDoDetalhe(),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;

    // Rola o detalhe como o usuário faz para chegar nos botões.
    Future<void> rolar(WidgetTester tester, double dy) async {
      expect(
        posicao(tester).maxScrollExtent,
        greaterThan(0),
        reason: 'o detalhe precisa rolar para o teste valer',
      );
      await tester.drag(rolavelDoDetalhe(), Offset(0, -dy));
      await tester.pumpAndSettle();
    }

    for (final origem in _Origem.values) {
      testWidgets('rolar e depois tocar em Curtir: a curtida chega à API '
          '(aberto pelo ${origem.name})', (tester) async {
        telaDeCelular(tester);
        await preparar(origem, publicacao: comFoto);
        await abrirDetalhe(tester, origem);

        await rolar(tester, 200);
        await tester.ensureVisible(find.text('Curtir'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Curtir'));
        await tester.pumpAndSettle();

        expect(curtidasRepo.curtidas, ['p1']);
        expect(find.text('Curtido'), findsOneWidget);
        expect(find.text('4 curtidas'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('rolar e depois tocar na lixeira: o comentário é apagado '
          'na API (aberto pelo ${origem.name})', (tester) async {
        telaDeCelular(tester);
        await preparar(origem, publicacao: comFoto);
        await abrirDetalhe(tester, origem);

        await rolar(tester, 300);
        await tester.ensureVisible(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();
        expect(find.text('Excluir comentário'), findsOneWidget);
        await tester.tap(find.text('Excluir'));
        await tester.pumpAndSettle();

        expect(comentariosRepo.deletados, ['c1']);
        expect(find.text('Que peixe bonito!'), findsNothing);
        expect(find.text('0 comentários'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    // Post de outra pessoa, já curtido por mim: autor e curtida vêm da API
    // no formato do feed (#267).
    final deOutraPessoa = Publicacao(
      id: 'p1',
      autorId: 'bruno',
      autorNome: 'Bruno Pescador',
      autorUsername: 'bruno',
      descricao: 'Tucunaré no rio Mogi',
      imagemUrl: comFoto.imagemUrl,
      curtidasCount: 7,
      comentariosCount: 1,
      jaCurtiu: true,
      criadoEm: DateTime(2026, 1, 1),
      atualizadoEm: DateTime(2026, 1, 1),
    );

    for (final origem in _Origem.values) {
      testWidgets('post de outra pessoa abre com o autor e a minha curtida '
          '(aberto pelo ${origem.name})', (tester) async {
        telaDeCelular(tester);
        await preparar(origem, publicacao: deOutraPessoa);
        await abrirDetalhe(tester, origem);

        // Na linha do autor (o meu nome aparece no meu comentário, abaixo).
        Finder naLinhaDoAutor(Finder f) => find.descendant(
          of: find.byKey(const ValueKey('detalhe-autor')),
          matching: f,
        );
        expect(naLinhaDoAutor(find.text('Bruno Pescador')), findsOneWidget);
        expect(
          naLinhaDoAutor(find.textContaining('@bruno · ')),
          findsOneWidget,
        );
        expect(naLinhaDoAutor(find.text(usuarioEu.nome)), findsNothing);

        await tester.ensureVisible(find.text('Curtido'));
        await tester.pumpAndSettle();
        expect(find.text('Curtido'), findsOneWidget);
        expect(find.text('Curtir'), findsNothing);
        expect(find.text('7 curtidas'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('rolar, tocar em Comentar e enviar: o comentário chega à '
          'API e entra na lista (aberto pelo ${origem.name})', (tester) async {
        telaDeCelular(tester);
        await preparar(origem, publicacao: comFoto);
        await abrirDetalhe(tester, origem);
        expect(find.text('1 comentário'), findsOneWidget);

        await rolar(tester, 200);
        await tester.ensureVisible(find.text('Comentar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Comentar'));
        await tester.pumpAndSettle();

        // O Comentar da barra leva ao campo fixo de comentário.
        final campo = find.byType(TextField);
        expect(tester.widget<TextField>(campo).focusNode?.hasFocus, isTrue);

        await tester.enterText(campo, 'Belo peixe, parabéns!');
        await tester.pump();
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        expect(comentariosRepo.criados, ['Belo peixe, parabéns!']);
        await tester.ensureVisible(find.text('Belo peixe, parabéns!'));
        await tester.pumpAndSettle();
        expect(find.text('Belo peixe, parabéns!'), findsOneWidget);
        expect(find.text('Que peixe bonito!'), findsOneWidget);
        expect(find.text('2 comentários'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('rolar até o fim dos comentários carrega a página 2', (
      tester,
    ) async {
      telaDeCelular(tester);
      // 26 comentários: a página 1 traz 20 (c1 a c20), a 2 traz o resto.
      await preparar(
        _Origem.perfil,
        publicacao: comFoto,
        outrosComentarios: 25,
      );
      await abrirDetalhe(tester, _Origem.perfil);
      expect(comentariosRepo.paginasPedidas, [1]);
      expect(find.text('Comentário 20'), findsOneWidget);
      expect(find.text('Comentário 21'), findsNothing);

      // Rola até o fim do conteúdo.
      await rolar(tester, posicao(tester).maxScrollExtent + 100);

      expect(comentariosRepo.paginasPedidas, [1, 2]);
      expect(find.text('Comentário 21'), findsOneWidget);
      expect(find.text('Comentário 26'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
