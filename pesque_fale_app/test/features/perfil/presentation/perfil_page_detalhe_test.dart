import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/router/rota_detalhe_publicacao.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/feed/data/comentarios_repository.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/aba_feed.dart';
import 'package:pesque_fale_app/features/feed/providers/feed_provider.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';
import 'package:pesque_fale_app/features/perfil/presentation/perfil_page.dart';
import 'package:pesque_fale_app/features/perfil/presentation/widgets/estatisticas_perfil.dart';
import 'package:pesque_fale_app/features/perfil/presentation/widgets/galeria_perfil.dart';
import 'package:pesque_fale_app/features/perfil/providers/perfil_provider.dart';
import 'package:pesque_fale_app/features/visualizacao_post/presentation/publicacao_detalhe_page.dart';
import 'package:pesque_fale_app/features/visualizacao_post/providers/publicacao_detalhe_provider.dart';

import '../support/fakes_perfil_detalhe.dart';

/// O próprio perfil com a grade e o contador reais, o detalhe aberto pela
/// galeria e o mesmo PublicacoesStore ligando perfil, feed e detalhe.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late PublicacoesStore store;
  late AuthProvider auth;
  late FakePerfilRepository perfilRepo;
  late FakePublicacoesRepository publicacoesRepo;
  late FeedProvider feed;
  late PerfilProvider perfil;

  final p1 = publicacaoDoEu(
    'p1',
    dia: 2,
    descricao: 'Tucunaré no rio Mogi',
    curtidasCount: 3,
    comentariosCount: 5,
  );
  final p2 = publicacaoDoEu('p2', dia: 1, descricao: 'Tilápia no fim da tarde');

  setUp(() async {
    store = PublicacoesStore();
    auth = await authLogado();
    publicacoesRepo = FakePublicacoesRepository(feed: [p1, p2]);
    perfilRepo = FakePerfilRepository(publicacoes: [p1, p2]);
    feed = criarFeedProvider(
      publicacoesRepo: publicacoesRepo,
      curtidasRepo: FakeCurtidasRepository(),
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
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<PublicacoesStore>.value(value: store),
          ChangeNotifierProvider<FeedProvider>.value(value: feed),
          ChangeNotifierProvider<PerfilProvider>.value(value: perfil),
          Provider<PublicacoesRepository>.value(value: publicacoesRepo),
          Provider<ComentariosRepository>.value(
            value: FakeComentariosRepository(),
          ),
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
  }

  Finder item(String id) => find.descendant(
    of: find.byType(GaleriaPerfil),
    matching: find.byKey(ValueKey(id)),
  );

  Finder contadorDePublicacoes(int valor) => find.descendant(
    of: find.byType(EstatisticasPerfil),
    matching: find.text('$valor'),
  );

  PublicacaoDetalheProvider detalheAberto(WidgetTester tester) =>
      Provider.of<PublicacaoDetalheProvider>(
        tester.element(find.byType(PublicacaoDetalhePage)),
        listen: false,
      );

  // A grade fica abaixo do cabeçalho: rola até o item antes de tocar nele.
  Future<void> mostrar(WidgetTester tester, String id) async {
    await tester.ensureVisible(item(id));
    await tester.pumpAndSettle();
  }

  Future<void> abrirDetalhe(WidgetTester tester, String id) async {
    await mostrar(tester, id);
    await tester.tap(item(id));
    await tester.pumpAndSettle();
    expect(find.byType(PublicacaoDetalhePage), findsOneWidget);
    expect(detalheAberto(tester).publicacao?.id, id);
  }

  Future<void> voltar(WidgetTester tester) async {
    Navigator.of(tester.element(find.byType(PublicacaoDetalhePage))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(PublicacaoDetalhePage), findsNothing);
  }

  /// Segura o item e devolve os textos do overlay (curtidas, comentários).
  Future<List<String>> contadoresDoToqueLongo(
    WidgetTester tester,
    String id,
  ) async {
    await mostrar(tester, id);
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

  testWidgets('excluir no detalhe aberto pela galeria: o post sai da grade e o '
      'contador de publicações diminui, sem recarregar', (tester) async {
    await montar(tester);
    expect(perfilRepo.cargas, 1);
    expect(item('p1'), findsOneWidget);
    expect(item('p2'), findsOneWidget);
    expect(contadorDePublicacoes(2), findsOneWidget);

    await abrirDetalhe(tester, 'p1');
    await detalheAberto(tester).excluir();
    await tester.pumpAndSettle();

    // O detalhe volta sozinho ao ver a publicação removida.
    expect(find.byType(PublicacaoDetalhePage), findsNothing);
    expect(find.byType(PerfilPage), findsOneWidget);
    expect(publicacoesRepo.deletadas, ['p1']);

    expect(item('p1'), findsNothing);
    expect(item('p2'), findsOneWidget);
    expect(contadorDePublicacoes(1), findsOneWidget);
    expect(contadorDePublicacoes(2), findsNothing);
    expect(perfilRepo.cargas, 1, reason: 'o perfil não pode ter recarregado');

    // O feed também perdeu o post, pelo mesmo store.
    expect(feed.paraVoce.map((p) => p.id), ['p2']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('curtir e comentar no detalhe aberto pela galeria: o toque '
      'longo na grade mostra os contadores novos', (tester) async {
    await montar(tester);
    expect(await contadoresDoToqueLongo(tester, 'p1'), ['3', '5']);

    await abrirDetalhe(tester, 'p1');
    // O que a AcoesBar e a lista de comentários do detalhe chamam.
    await feed.curtirOuDescurtir(detalheAberto(tester).publicacao!);
    detalheAberto(tester).aplicarDeltaComentarios(1);
    await tester.pump();
    await voltar(tester);

    expect(await contadoresDoToqueLongo(tester, 'p1'), ['4', '6']);
    expect(await contadoresDoToqueLongo(tester, 'p2'), ['0', '0']);
    expect(perfilRepo.cargas, 1, reason: 'o perfil não pode ter recarregado');
    expect(publicacoesRepo.buscasPorId, 0);
    expect(tester.takeException(), isNull);
  });
}
