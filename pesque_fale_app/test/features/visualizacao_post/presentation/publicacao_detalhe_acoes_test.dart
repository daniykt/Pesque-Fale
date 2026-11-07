import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/data/paged_result.dart';
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
import 'package:pesque_fale_app/features/visualizacao_post/providers/publicacao_detalhe_provider.dart';

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

/// Um comentário do usuário logado, que pode ser apagado.
class _ComentariosRepository implements ComentariosRepository {
  final List<String> deletados = [];

  final _meu = Comentario(
    id: 'c1',
    publicacaoId: 'p1',
    autorId: idEu,
    autorNome: usuarioEu.nome,
    texto: 'Que peixe bonito!',
    criadoEm: DateTime(2026, 1, 3),
  );

  @override
  Future<PagedResult<Comentario>> listar(
    String publicacaoId, {
    int pagina = 1,
    int porPagina = 20,
  }) async => PagedResult(
    items: deletados.contains('c1') ? const [] : [_meu],
    total: 1,
    pagina: pagina,
    porPagina: porPagina,
  );

  @override
  Future<Comentario> criar(String publicacaoId, String texto) =>
      throw UnimplementedError();

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

  Future<void> preparar(_Origem origem) async {
    store = PublicacoesStore();
    auth = await authLogado();
    curtidasRepo = FakeCurtidasRepository();
    comentariosRepo = _ComentariosRepository();
    // Só o feed carrega o p1 nas listas dele. Pelo perfil e pela
    // notificação, o post não está no feed.
    publicacoesRepo = _PublicacoesRepository(
      feed: origem == _Origem.feed ? [p1] : const [],
      porId: p1,
    );
    feed = criarFeedProvider(
      publicacoesRepo: publicacoesRepo,
      curtidasRepo: curtidasRepo,
      authProvider: auth,
      store: store,
    );
    await feed.trocarAba(AbaFeed.paraVoce);
    if (origem == _Origem.perfil) store.inserirSeAusente([p1]);
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
          // Mesma rota do main.dart.
          onGenerateRoute: (settings) {
            if (settings.name != '/publicacao/detalhe') return null;
            final args = settings.arguments;
            return MaterialPageRoute(
              settings: settings,
              builder: (context) =>
                  ChangeNotifierProvider<PublicacaoDetalheProvider>(
                    create: (ctx) => PublicacaoDetalheProvider(
                      publicacoesRepository: ctx.read<PublicacoesRepository>(),
                      store: ctx.read<PublicacoesStore>(),
                      publicacaoInicial: args is Publicacao ? args : null,
                      publicacaoId: args is String ? args : null,
                    )..carregar(),
                    child: const PublicacaoDetalhePage(),
                  ),
            );
          },
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
}
