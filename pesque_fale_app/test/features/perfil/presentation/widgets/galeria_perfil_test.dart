import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/perfil/presentation/widgets/galeria_perfil.dart';
import 'package:pesque_fale_app/shared/widgets/imagem_placeholder.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montar(
    WidgetTester tester, {
    bool isOwnProfile = true,
    List<Publicacao> publicacoes = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: GaleriaPerfil(
              publicacoes: publicacoes,
              isOwnProfile: isOwnProfile,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra o título Publicações como cabeçalho', (tester) async {
    await montar(tester);

    expect(find.text('Publicações'), findsOneWidget);
    final semantica = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.text('Publicações'),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(semantica.properties.header, isTrue);
  });

  testWidgets('não mostra abas nem os placeholders das abas futuras', (
    tester,
  ) async {
    await montar(tester);

    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Equipamentos'), findsNothing);
    expect(find.text('Locais Salvos'), findsNothing);
    expect(find.textContaining('Em breve'), findsNothing);
  });

  testWidgets('no próprio perfil sem publicações oferece Nova Publicação', (
    tester,
  ) async {
    await montar(tester);

    expect(find.text('Nenhuma publicação ainda'), findsOneWidget);
    expect(find.text('Nova Publicação'), findsOneWidget);
  });

  testWidgets('no perfil de outro usuário não oferece Nova Publicação', (
    tester,
  ) async {
    await montar(tester, isOwnProfile: false);

    expect(find.text('Nenhuma publicação ainda'), findsOneWidget);
    expect(find.text('Nova Publicação'), findsNothing);
  });

  testWidgets('em 360dp com fonte 1.3 não estoura o layout', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await montar(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('publicação sem imagem mostra o quadrado de texto', (
    tester,
  ) async {
    await montar(
      tester,
      publicacoes: [
        Publicacao(
          id: 'p1',
          autorId: 'u1',
          autorNome: 'Ana',
          criadoEm: DateTime(2026, 1, 1),
          atualizadoEm: DateTime(2026, 1, 1),
        ),
      ],
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byType(ImagemIndisponivel), findsNothing);
    expect(find.byIcon(Icons.notes), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'remover uma publicação mantém o toque longo na publicação certa',
    (tester) async {
      Publicacao pub(String id, int curtidas) => Publicacao(
        id: id,
        autorId: 'u1',
        autorNome: 'Ana',
        curtidasCount: curtidas,
        criadoEm: DateTime(2026, 1, 1),
        atualizadoEm: DateTime(2026, 1, 1),
      );
      final primeira = pub('p1', 3);
      final segunda = pub('p2', 7);
      await montar(tester, publicacoes: [primeira, segunda]);

      final gesto = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('p2'))),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.text('7'), findsOneWidget);

      await montar(tester, publicacoes: [segunda]);

      expect(find.text('7'), findsOneWidget);
      await gesto.up();
    },
  );

  group('abrir o detalhe', () {
    Publicacao pub(String id, {String? descricao, int curtidas = 0}) =>
        Publicacao(
          id: id,
          autorId: 'u1',
          autorNome: 'Ana',
          descricao: descricao,
          curtidasCount: curtidas,
          comentariosCount: 2,
          criadoEm: DateTime(2026, 1, 1),
          atualizadoEm: DateTime(2026, 1, 1),
        );

    final grade = [
      pub('p1', descricao: 'Tilápia no fim da tarde', curtidas: 3),
      pub('p2', descricao: 'Pescaria no rio Mogi', curtidas: 7),
      pub('p3'),
    ];

    // Registra o que chega na rota do detalhe, com o mesmo nome usado pelo
    // feed e pelo main.dart.
    Future<List<RouteSettings>> montarComRota(
      WidgetTester tester, {
      ThemeData? tema,
      bool isOwnProfile = true,
    }) async {
      final abertas = <RouteSettings>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: tema ?? AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: GaleriaPerfil(
                publicacoes: grade,
                isOwnProfile: isOwnProfile,
              ),
            ),
          ),
          onGenerateRoute: (settings) {
            abertas.add(settings);
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('Detalhe aberto')),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      return abertas;
    }

    // Tema criado dentro do teste: montar o ThemeData no main() carrega a
    // fonte fora de um teste e quebra o arquivo inteiro.
    for (final (nomeTema, criarTema, isOwnProfile) in [
      ('claro, perfil próprio', () => AppTheme.light, true),
      ('escuro, perfil de outro', () => AppTheme.dark, false),
    ]) {
      testWidgets('tocar no item abre o detalhe da publicação certa '
          '($nomeTema)', (tester) async {
        final abertas = await montarComRota(
          tester,
          tema: criarTema(),
          isOwnProfile: isOwnProfile,
        );

        await tester.tap(find.byKey(const ValueKey('p2')));
        await tester.pumpAndSettle();

        expect(abertas, hasLength(1));
        expect(abertas.single.name, '/publicacao/detalhe');
        final argumento = abertas.single.arguments;
        expect(argumento, isA<Publicacao>());
        expect((argumento! as Publicacao).id, 'p2');
        expect(find.text('Detalhe aberto'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('tocar mostra o ripple do tema no item', (tester) async {
      await montarComRota(tester);

      final gesto = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('p1'))),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final inkWell = find.descendant(
        of: find.byKey(const ValueKey('p1')),
        matching: find.byType(InkWell),
      );
      expect(inkWell, findsOneWidget);
      // Material do próprio item (o mais próximo do InkWell), não o do
      // Scaffold: é nele que o ripple é desenhado, por cima da imagem.
      final MaterialInkController ink = Material.of(tester.element(inkWell));
      expect(
        (ink as dynamic).debugInkFeatures,
        isNotEmpty,
        reason: 'o InkWell desenha o ripple enquanto o dedo está no item',
      );
      await gesto.up();
      await tester.pumpAndSettle();
    });

    testWidgets('toque longo mostra os contadores e não abre o detalhe', (
      tester,
    ) async {
      final abertas = await montarComRota(tester);
      expect(find.text('7'), findsNothing);

      final gesto = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('p2'))),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.text('7'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      await gesto.up();
      await tester.pumpAndSettle();

      expect(find.text('7'), findsNothing);
      expect(abertas, isEmpty);
      expect(find.text('Detalhe aberto'), findsNothing);
    });

    testWidgets('cada item tem um rótulo que o identifica no leitor de tela', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await montarComRota(tester);

      SemanticsData dadosDo(String id) =>
          tester.getSemantics(find.byKey(ValueKey(id))).getSemanticsData();

      // Cada item é um nó só: botão, com toque (abrir) e toque longo
      // (contadores). Os três são posts sem foto: o quadrado de texto fica
      // fora da semântica, então o rótulo é exatamente o do item, sem
      // "Imagem indisponível" e sem a descrição lida de novo.
      final rotulos = <String, String>{
        'p1': 'Abrir publicação: Tilápia no fim da tarde',
        'p2': 'Abrir publicação: Pescaria no rio Mogi',
        'p3': 'Abrir publicação 3 de 3',
      };
      for (final MapEntry(key: id, value: rotulo) in rotulos.entries) {
        final dados = dadosDo(id);
        expect(dados.label, rotulo, reason: id);
        expect(dados.flagsCollection.isButton, isTrue, reason: id);
        expect(dados.hasAction(SemanticsAction.tap), isTrue, reason: id);
        expect(dados.hasAction(SemanticsAction.longPress), isTrue, reason: id);
      }

      // Nenhum item fica com o rótulo genérico repetido.
      final labels = rotulos.keys.map((id) => dadosDo(id).label).toSet();
      expect(labels, hasLength(3));
      expect(
        labels.where((l) => l.split('\n').first == 'Abrir publicação'),
        isEmpty,
      );
      semantics.dispose();
    });
  });

  group('publicação sem foto e foto com erro', () {
    const descricaoLonga =
        'Saímos cedo para o rio Mogi, o dia estava nublado e a água turva, '
        'mas depois do almoço o tucunaré começou a bater forte na isca de '
        'superfície e a família inteira pegou pelo menos um peixe bom.';

    Publicacao pub(
      String id, {
      String? descricao,
      String? imagemUrl,
      int curtidas = 0,
    }) => Publicacao(
      id: id,
      autorId: 'u1',
      autorNome: 'Ana',
      descricao: descricao,
      imagemUrl: imagemUrl,
      curtidasCount: curtidas,
      comentariosCount: 2,
      criadoEm: DateTime(2026, 1, 1),
      atualizadoEm: DateTime(2026, 1, 1),
    );

    Future<List<RouteSettings>> montarGrade(
      WidgetTester tester,
      List<Publicacao> publicacoes, {
      ThemeData? tema,
    }) async {
      final abertas = <RouteSettings>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: tema ?? AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: GaleriaPerfil(
                publicacoes: publicacoes,
                isOwnProfile: true,
              ),
            ),
          ),
          onGenerateRoute: (settings) {
            abertas.add(settings);
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('Detalhe aberto')),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      return abertas;
    }

    Finder dentroDo(String id, Finder finder) =>
        find.descendant(of: find.byKey(ValueKey(id)), matching: finder);

    // O RichText do Text da descrição (o Icon também desenha um RichText).
    RenderParagraph paragrafoDaDescricao(WidgetTester tester, String id) =>
        tester.renderObject<RenderParagraph>(
          find.descendant(
            of: dentroDo(id, find.byType(Text)),
            matching: find.byType(RichText),
          ),
        );

    // Tema criado dentro do teste (ver o comentário do grupo anterior).
    for (final (nomeTema, criarTema, cores) in [
      ('claro', () => AppTheme.light, AppColors.light),
      ('escuro', () => AppTheme.dark, AppColors.dark),
    ]) {
      testWidgets('sem foto: quadrado de texto com a descrição e o ícone '
          '(tema $nomeTema)', (tester) async {
        await montarGrade(tester, [
          pub('p1', descricao: 'Pescaria no rio Mogi'),
        ], tema: criarTema());

        expect(dentroDo('p1', find.text('Pescaria no rio Mogi')), findsOne);
        final icone = tester.widget<Icon>(
          dentroDo('p1', find.byIcon(Icons.notes)),
        );
        expect(icone.color, cores.textSecondary);
        expect(find.byType(ImagemIndisponivel), findsNothing);
        expect(find.byType(Image), findsNothing);

        // Fundo de superfície com contorno, para se destacar do fundo da
        // grade, que é o background do tema.
        final decoracoes = tester
            .widgetList<DecoratedBox>(dentroDo('p1', find.byType(DecoratedBox)))
            .map((d) => d.decoration)
            .whereType<BoxDecoration>();
        expect(
          decoracoes.any(
            (d) =>
                d.color == cores.surface &&
                d.border == Border.all(color: cores.border),
          ),
          isTrue,
        );
        expect(cores.surface, isNot(cores.background));

        final texto = tester.widget<Text>(
          dentroDo('p1', find.text('Pescaria no rio Mogi')),
        );
        expect(texto.style?.color, cores.textPrimary);
        expect(
          texto.style?.fontSize,
          criarTema().textTheme.bodySmall?.fontSize,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('foto que falha ao carregar mostra Imagem indisponível '
          '(tema $nomeTema)', (tester) async {
        await montarGrade(tester, [
          pub(
            'p1',
            descricao: 'Pescaria no rio Mogi',
            imagemUrl:
                'https://res.cloudinary.com/demo/image/upload/quebrada.jpg',
          ),
        ], tema: criarTema());

        expect(dentroDo('p1', find.byType(Image)), findsOneWidget);
        expect(dentroDo('p1', find.byType(ImagemIndisponivel)), findsOne);
        expect(find.byIcon(Icons.notes), findsNothing);
        expect(find.text('Pescaria no rio Mogi'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('sem foto e sem descrição: só o ícone, centralizado '
          '(tema $nomeTema)', (tester) async {
        await montarGrade(tester, [pub('p1')], tema: criarTema());

        final icone = dentroDo('p1', find.byIcon(Icons.notes));
        expect(icone, findsOneWidget);
        expect(dentroDo('p1', find.byType(Text)), findsNothing);
        expect(find.byType(ImagemIndisponivel), findsNothing);
        expect(
          tester.getCenter(icone),
          tester.getCenter(find.byKey(const ValueKey('p1'))),
        );
        expect(tester.takeException(), isNull);
      });
    }

    String urlNaGrade(WidgetTester tester, String id) =>
        (tester.widget<Image>(dentroDo(id, find.byType(Image))).image
                as NetworkImage)
            .url;

    testWidgets('foto do Cloudinary carrega a miniatura quadrada de 360', (
      tester,
    ) async {
      await montarGrade(tester, [
        pub(
          'p1',
          imagemUrl:
              'https://res.cloudinary.com/pesque-fale/image/upload/v1730000000/publicacoes/abc.jpg',
        ),
      ]);

      expect(
        urlNaGrade(tester, 'p1'),
        'https://res.cloudinary.com/pesque-fale/image/upload/'
        'c_fill,w_360,h_360,q_auto,f_auto/v1730000000/publicacoes/abc.jpg',
      );
    });

    testWidgets('foto de fora do Cloudinary chega igual ao Image.network', (
      tester,
    ) async {
      const picsum = 'https://picsum.photos/seed/ana-post-1/400/400';
      await montarGrade(tester, [pub('p1', imagemUrl: picsum)]);

      expect(urlNaGrade(tester, 'p1'), picsum);
    });

    testWidgets('descrição longa: no máximo 4 linhas, com reticências', (
      tester,
    ) async {
      await montarGrade(tester, [pub('p1', descricao: descricaoLonga)]);

      final texto = tester.widget<Text>(dentroDo('p1', find.byType(Text)));
      expect(texto.maxLines, 4);
      expect(texto.overflow, TextOverflow.ellipsis);
      final paragrafo = paragrafoDaDescricao(tester, 'p1');
      expect(paragrafo.didExceedMaxLines, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'em 360dp com fonte 1.3: menos linhas, inteiras e sem estouro',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await montarGrade(tester, [pub('p1', descricao: descricaoLonga)]);

        final texto = tester.widget<Text>(dentroDo('p1', find.byType(Text)));
        expect(texto.maxLines, inInclusiveRange(1, 3));

        // As linhas mostradas cabem inteiras na área do texto: a altura de
        // que o parágrafo precisa (já limitado pelo maxLines) não passa da
        // altura disponível, então a última linha não sai cortada.
        final paragrafo = paragrafoDaDescricao(tester, 'p1');
        final alturaNecessaria = paragrafo.getMinIntrinsicHeight(
          paragrafo.size.width,
        );
        expect(
          alturaNecessaria,
          lessThanOrEqualTo(paragrafo.constraints.maxHeight),
        );
        expect(paragrafo.didExceedMaxLines, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('quadrado de texto abre o detalhe ao tocar', (tester) async {
      final abertas = await montarGrade(tester, [
        pub('p1', descricao: 'Tilápia no fim da tarde'),
        pub('p2', descricao: 'Pescaria no rio Mogi'),
      ]);
      expect(dentroDo('p2', find.byIcon(Icons.notes)), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('p2')));
      await tester.pumpAndSettle();

      expect(abertas, hasLength(1));
      expect(abertas.single.name, '/publicacao/detalhe');
      expect((abertas.single.arguments! as Publicacao).id, 'p2');
    });

    testWidgets('quadrado de texto mostra os contadores no toque longo', (
      tester,
    ) async {
      final abertas = await montarGrade(tester, [
        pub('p1', descricao: 'Pescaria no rio Mogi', curtidas: 7),
      ]);

      final gesto = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('p1'))),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.text('7'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      await gesto.up();
      await tester.pumpAndSettle();
      expect(find.text('7'), findsNothing);
      expect(abertas, isEmpty);
    });

    testWidgets('semântica: só o rótulo do item, sem Imagem indisponível e '
        'sem a descrição repetida', (tester) async {
      final semantics = tester.ensureSemantics();
      await montarGrade(tester, [
        pub('p1', descricao: descricaoLonga),
        pub('p2'),
      ]);

      final rotuloComDescricao = tester
          .getSemantics(find.byKey(const ValueKey('p1')))
          .getSemanticsData()
          .label;
      expect(
        rotuloComDescricao,
        rotuloItemGaleria(
          pub('p1', descricao: descricaoLonga),
          posicao: 1,
          total: 2,
        ),
      );
      expect(rotuloComDescricao, isNot(contains('Imagem indisponível')));
      // A descrição entra uma vez só (o começo, no rótulo).
      expect('Saímos cedo'.allMatches(rotuloComDescricao), hasLength(1));

      final rotuloSemDescricao = tester
          .getSemantics(find.byKey(const ValueKey('p2')))
          .getSemanticsData()
          .label;
      expect(rotuloSemDescricao, 'Abrir publicação 2 de 2');

      expect(
        find.bySemanticsLabel(RegExp('Imagem indisponível')),
        findsNothing,
      );
      semantics.dispose();
    });
  });

  group('rotuloItemGaleria', () {
    Publicacao comDescricao(String? descricao) => Publicacao(
      id: 'p1',
      autorId: 'u1',
      autorNome: 'Ana',
      descricao: descricao,
      criadoEm: DateTime(2026, 1, 1),
      atualizadoEm: DateTime(2026, 1, 1),
    );

    test('descrição curta entra inteira', () {
      expect(
        rotuloItemGaleria(
          comDescricao('Pescaria no rio Mogi'),
          posicao: 1,
          total: 12,
        ),
        'Abrir publicação: Pescaria no rio Mogi',
      );
    });

    test('descrição longa é cortada em 40 caracteres com reticências', () {
      const longa =
          'Pescaria no rio Mogi com a família inteira, saiu tucunaré grande';
      final rotulo = rotuloItemGaleria(
        comDescricao(longa),
        posicao: 1,
        total: 12,
      );

      expect(
        rotulo,
        'Abrir publicação: ${longa.substring(0, 40).trimRight()}…',
      );
    });

    test('quebras de linha e espaços repetidos viram um espaço só', () {
      expect(
        rotuloItemGaleria(
          comDescricao('  Pescaria\n\nno   rio  '),
          posicao: 1,
          total: 12,
        ),
        'Abrir publicação: Pescaria no rio',
      );
    });

    test('não corta um emoji no meio', () {
      final rotulo = rotuloItemGaleria(
        comDescricao('${'a' * 39}🎣🎣'),
        posicao: 1,
        total: 12,
      );

      expect(rotulo, 'Abrir publicação: ${'a' * 39}🎣…');
    });

    test('sem descrição (ou só espaços) usa a posição na grade', () {
      expect(
        rotuloItemGaleria(comDescricao(null), posicao: 2, total: 12),
        'Abrir publicação 2 de 12',
      );
      expect(
        rotuloItemGaleria(comDescricao('   '), posicao: 5, total: 12),
        'Abrir publicação 5 de 12',
      );
    });
  });
}
