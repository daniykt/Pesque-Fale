import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/router/rota_detalhe_publicacao.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/feed/data/comentarios_repository.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/providers/feed_provider.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';
import 'package:pesque_fale_app/features/visualizacao_post/presentation/publicacao_detalhe_page.dart';
import 'package:pesque_fale_app/features/visualizacao_post/presentation/widgets/foto_publicacao.dart';

import '../../perfil/support/fakes_perfil_detalhe.dart';

/// O detalhe aberto pela rota do app, com o layout da #317.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Publicacao post({
    String autorId = idEu,
    String autorNome = 'Ana Pescadora',
    String? descricao = 'Tucunaré no rio Mogi',
    String? imagemUrl =
        'https://res.cloudinary.com/demo/image/upload/v1/publicacoes/tucunare.jpg',
    String? pontoId = 'ponto-1',
    String? localTexto = 'Rio Mogi',
    double? avaliacaoNota = 4.5,
    List<String> tags = const ['tucunare'],
  }) => Publicacao(
    id: 'p1',
    autorId: autorId,
    autorNome: autorNome,
    autorUsername: 'ana_pesca',
    pontoId: pontoId,
    descricao: descricao,
    imagemUrl: imagemUrl,
    localTexto: localTexto,
    avaliacaoNota: avaliacaoNota,
    tags: tags,
    curtidasCount: 3,
    comentariosCount: 0,
    criadoEm: DateTime(2026, 1, 1),
    atualizadoEm: DateTime(2026, 1, 1),
  );

  /// Abre o detalhe e devolve as outras rotas empurradas a partir dele.
  Future<List<RouteSettings>> abrir(
    WidgetTester tester,
    Publicacao publicacao, {
    ThemeData? tema,
  }) async {
    final store = PublicacoesStore()..inserirSeAusente([publicacao]);
    final auth = await authLogado();
    final publicacoesRepo = FakePublicacoesRepository(feed: const []);
    final FeedProvider feed = criarFeedProvider(
      publicacoesRepo: publicacoesRepo,
      curtidasRepo: FakeCurtidasRepository(),
      authProvider: auth,
      store: store,
    );
    final outrasRotas = <RouteSettings>[];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<PublicacoesStore>.value(value: store),
          ChangeNotifierProvider<FeedProvider>.value(value: feed),
          Provider<PublicacoesRepository>.value(value: publicacoesRepo),
          Provider<ComentariosRepository>.value(
            value: FakeComentariosRepository(),
          ),
        ],
        child: MaterialApp(
          theme: tema ?? AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  rotaDetalhePublicacaoNome,
                  arguments: publicacao,
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
          onGenerateRoute: (settings) {
            final detalhe = rotaDetalhePublicacao(settings);
            if (detalhe != null) return detalhe;
            outrasRotas.add(settings);
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Outra tela')),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(PublicacaoDetalhePage), findsOneWidget);
    return outrasRotas;
  }

  Finder linhaAutor() => find.byKey(const ValueKey('detalhe-autor'));
  Finder cardLocal() => find.byKey(const ValueKey('detalhe-card-local'));
  Finder menu() => find.byTooltip('Mais opções');

  testWidgets('blocos na ordem autor, texto, foto, ações e local, com o ⋯ na '
      'linha do autor', (tester) async {
    await abrir(tester, post());

    final autor = tester.getRect(linhaAutor());
    final texto = tester.getTopLeft(find.text('Tucunaré no rio Mogi')).dy;
    final tags = tester.getTopLeft(find.text('#tucunare')).dy;
    final foto = tester.getTopLeft(find.byType(FotoPublicacao)).dy;
    final acoes = tester.getTopLeft(find.text('Curtir')).dy;
    final local = tester.getTopLeft(cardLocal()).dy;

    expect(autor.top, lessThan(texto));
    expect(texto, lessThan(tags));
    expect(tags, lessThan(foto));
    expect(foto, lessThan(acoes));
    expect(acoes, lessThan(local));

    // O ⋯ está na mesma linha do autor, e não na barra superior.
    expect(menu(), findsOneWidget);
    final centroMenu = tester.getCenter(menu()).dy;
    expect(centroMenu, greaterThan(autor.top));
    expect(centroMenu, lessThan(autor.bottom));
    expect(
      find.descendant(of: find.byType(AppBar), matching: menu()),
      findsNothing,
    );
    expect(tester.widget<AppBar>(find.byType(AppBar)).actions, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a linha do autor mostra @username · tempo e abre o perfil', (
    tester,
  ) async {
    final rotas = await abrir(tester, post());

    expect(find.text('@ana_pesca · 01/01/2026'), findsOneWidget);
    expect(
      tester.getSize(linhaAutor()).height,
      greaterThanOrEqualTo(kMinInteractiveDimension),
    );

    await tester.tap(find.text('Ana Pescadora'));
    await tester.pumpAndSettle();

    expect(rotas.single.name, '/perfil');
    expect(rotas.single.arguments, idEu);
  });

  testWidgets('o ⋯ do próprio post mostra Excluir publicação', (tester) async {
    await abrir(tester, post());

    await tester.tap(menu());
    await tester.pumpAndSettle();

    expect(find.text('Excluir publicação'), findsOneWidget);
    expect(find.text('Copiar link'), findsOneWidget);
  });

  testWidgets('o ⋯ do post de outra pessoa não mostra Excluir publicação', (
    tester,
  ) async {
    await abrir(tester, post(autorId: 'outra-pessoa'));

    await tester.tap(menu());
    await tester.pumpAndSettle();

    expect(find.text('Excluir publicação'), findsNothing);
    expect(find.text('Copiar link'), findsOneWidget);
  });

  testWidgets('com foto, o texto tem 16px', (tester) async {
    await abrir(tester, post());

    expect(find.byType(FotoPublicacao), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Tucunaré no rio Mogi')).style?.fontSize,
      16,
    );
  });

  testWidgets('sem foto, o bloco da foto some e o texto vai a 18px', (
    tester,
  ) async {
    await abrir(tester, post(imagemUrl: null));
    expect(find.byType(FotoPublicacao), findsNothing);
    expect(
      tester.widget<Text>(find.text('Tucunaré no rio Mogi')).style?.fontSize,
      18,
    );
    expect(tester.takeException(), isNull);
  });

  group('card do local', () {
    testWidgets('mostra o local e a nota do pescador e abre o local', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final rotas = await abrir(tester, post());

      expect(
        find.descendant(of: cardLocal(), matching: find.text('Rio Mogi')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: cardLocal(),
          matching: find.text('4,5 · nota do pescador'),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSize(cardLocal()).height,
        greaterThanOrEqualTo(kMinInteractiveDimension),
      );
      expect(
        find.bySemanticsLabel('Local: Rio Mogi. Nota do pescador: 4,5 de 5'),
        findsOneWidget,
      );

      await tester.ensureVisible(cardLocal());
      await tester.pumpAndSettle();
      await tester.tap(cardLocal());
      await tester.pumpAndSettle();

      expect(rotas.single.name, '/pontos');
      expect(rotas.single.arguments, 'ponto-1');
      semantics.dispose();
    });

    testWidgets('local sem ponto não é tocável', (tester) async {
      final rotas = await abrir(tester, post(pontoId: null));

      expect(
        find.descendant(of: cardLocal(), matching: find.byType(InkWell)),
        findsNothing,
      );
      await tester.ensureVisible(cardLocal());
      await tester.pumpAndSettle();
      await tester.tap(cardLocal());
      await tester.pumpAndSettle();

      expect(rotas, isEmpty);
      expect(find.byType(PublicacaoDetalhePage), findsOneWidget);
    });

    testWidgets('sem local nem nota, não há card', (tester) async {
      await abrir(tester, post(localTexto: null, avaliacaoNota: null));

      expect(cardLocal(), findsNothing);
    });
  });

  // Tema criado dentro do teste: o GoogleFonts não pode carregar fontes fora
  // de um teste.
  for (final (nomeTema, criarTema, cores, iconesDaBarraDeStatus) in [
    ('claro', () => AppTheme.light, AppColors.light, Brightness.dark),
    ('escuro', () => AppTheme.dark, AppColors.dark, Brightness.light),
  ]) {
    testWidgets('barra superior em surface, com seta e título em '
        'primaryAccent e ícones da barra de status certos '
        '(tema $nomeTema)', (tester) async {
      await abrir(tester, post(), tema: criarTema());

      final barra = tester.widget<AppBar>(find.byType(AppBar));
      expect(barra.backgroundColor, cores.surface);
      expect(barra.foregroundColor, cores.primaryAccent);
      expect(barra.shape, Border(bottom: BorderSide(color: cores.border)));
      expect(
        barra.systemOverlayStyle?.statusBarIconBrightness,
        iconesDaBarraDeStatus,
      );
      expect(
        tester.widget<Text>(find.text('Publicação')).style?.color,
        cores.primaryAccent,
      );
      expect(find.byType(BackButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('em 360dp com fonte 1.3 não estoura (tema $nomeTema)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await abrir(
        tester,
        post(
          autorNome: 'Ana Maria Pescadora de Tucunaré do Rio Mogi Guaçu',
          localTexto: 'Represa do Rio Mogi Guaçu, perto da ponte velha',
          tags: const ['tucunare', 'isca_artificial', 'rio_mogi', 'familia'],
        ),
        tema: criarTema(),
      );
      await tester.ensureVisible(cardLocal());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }

  test('estiloBarraDeStatus só mexe na barra de status', () {
    final claro = estiloBarraDeStatus(Brightness.light);
    expect(claro.statusBarIconBrightness, Brightness.dark);
    expect(claro.statusBarBrightness, Brightness.light);
    expect(claro.systemNavigationBarColor, isNull);

    final escuro = estiloBarraDeStatus(Brightness.dark);
    expect(escuro.statusBarIconBrightness, Brightness.light);
    expect(escuro.statusBarBrightness, Brightness.dark);
    expect(escuro.systemNavigationBarColor, isNull);
  });
}
