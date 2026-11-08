import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';

import 'package:pesque_fale_app/features/visualizacao_post/presentation/widgets/foto_publicacao.dart';
import 'package:pesque_fale_app/shared/widgets/imagem_placeholder.dart';
import 'package:pesque_fale_app/shared/widgets/visualizador_imagem.dart';

/// Cores do app sem GoogleFonts: as fontes não são empacotadas nos testes e,
/// com o runAsync que decodifica a imagem, o carregamento delas falha e
/// derruba o teste (o mesmo motivo do crop_imagem_page_test).
final _temaClaro = ThemeData(extensions: const [AppColors.light]);
final _temaEscuro = ThemeData(
  brightness: Brightness.dark,
  extensions: const [AppColors.dark],
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  /// PNG de [largura] × [altura] em memória: a imagem de rede não carrega
  /// em widget test.
  Future<MemoryImage> imagem(
    WidgetTester tester,
    int largura,
    int altura,
  ) async {
    final bytes = await tester.runAsync(() async {
      final gravador = ui.PictureRecorder();
      Canvas(gravador).drawRect(
        Rect.fromLTWH(0, 0, largura.toDouble(), altura.toDouble()),
        Paint()..color = const Color(0xFF2E7D32),
      );
      final img = await gravador.endRecording().toImage(largura, altura);
      final dados = await img.toByteData(format: ui.ImageByteFormat.png);
      return dados!.buffer.asUint8List();
    });
    return MemoryImage(bytes!);
  }

  Future<void> montar(
    WidgetTester tester, {
    required ImageProvider? imagemDeTeste,
    ThemeData? tema,
    String url = 'https://res.cloudinary.com/demo/image/upload/v1/foto.jpg',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: tema ?? _temaClaro,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 360,
              child: FotoPublicacao(url: url, imagem: imagemDeTeste),
            ),
          ),
        ),
      ),
    );
    if (imagemDeTeste != null) {
      await tester.runAsync(
        () => precacheImage(
          imagemDeTeste,
          tester.element(find.byType(FotoPublicacao)),
        ),
      );
    }
    await tester.pumpAndSettle();
  }

  Size tamanhoDaFoto(WidgetTester tester) => tester.getSize(
    find.descendant(
      of: find.byType(FotoPublicacao),
      matching: find.byType(Image),
    ),
  );

  testWidgets('foto em pé fica na altura máxima de 4:5 e é cortada', (
    tester,
  ) async {
    await montar(tester, imagemDeTeste: await imagem(tester, 40, 80));

    // 1:2 ficaria com 720 de altura; o limite de 4:5 deixa em 450.
    expect(tamanhoDaFoto(tester), const Size(360, 450));
    final foto = tester.widget<Image>(find.byType(Image));
    expect(foto.fit, BoxFit.cover);
    expect(find.text('Toque para ampliar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('foto deitada aparece inteira, na proporção dela', (
    tester,
  ) async {
    await montar(tester, imagemDeTeste: await imagem(tester, 80, 40));

    expect(tamanhoDaFoto(tester), const Size(360, 180));
    expect(tester.takeException(), isNull);
  });

  testWidgets('foto quadrada também cabe inteira', (tester) async {
    await montar(tester, imagemDeTeste: await imagem(tester, 50, 50));

    expect(tamanhoDaFoto(tester), const Size(360, 360));
  });

  testWidgets('foto que falha mostra Imagem indisponível em 4:5, sem o selo', (
    tester,
  ) async {
    await montar(tester, imagemDeTeste: null);

    expect(find.byType(ImagemIndisponivel), findsOneWidget);
    expect(
      tester.getSize(find.byType(ImagemIndisponivel)),
      const Size(360, 450),
    );
    expect(find.text('Toque para ampliar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('o leitor de tela lê a foto como botão de ampliar', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await montar(tester, imagemDeTeste: await imagem(tester, 40, 80));

    final dados = tester
        .getSemantics(find.bySemanticsLabel(RegExp('Toque para ampliar')))
        .getSemanticsData();
    expect(dados.label, contains('Foto da publicação. Toque para ampliar'));
    expect(dados.flagsCollection.isButton, isTrue);
    expect(dados.hasAction(ui.SemanticsAction.tap), isTrue);
    semantics.dispose();
  });

  group('tela cheia', () {
    for (final (nomeTema, criarTema) in [
      ('claro', () => _temaClaro),
      ('escuro', () => _temaEscuro),
    ]) {
      testWidgets('tocar na foto abre a tela cheia escura, que fecha pelo '
          'botão (tema $nomeTema)', (tester) async {
        final foto = await imagem(tester, 40, 80);
        await montar(tester, imagemDeTeste: foto, tema: criarTema());

        await tester.tap(find.byType(FotoPublicacao));
        await tester.pumpAndSettle();

        expect(find.byType(VisualizadorImagem), findsOneWidget);
        final cheia = tester.widget<Image>(
          find.descendant(
            of: find.byType(VisualizadorImagem),
            matching: find.byType(Image),
          ),
        );
        expect(cheia.image, foto, reason: 'a mesma imagem, já em cache');
        expect(cheia.fit, BoxFit.contain);
        expect(find.byType(InteractiveViewer), findsOneWidget);

        // Fundo escuro nos dois temas, com ícones claros na barra de status.
        final fundo = tester.widget<Scaffold>(
          find.descendant(
            of: find.byType(VisualizadorImagem),
            matching: find.byType(Scaffold),
          ),
        );
        expect(fundo.backgroundColor, AppColors.dark.background);
        final estilo = tester
            .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
              find.descendant(
                of: find.byType(VisualizadorImagem),
                matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
              ),
            )
            .value;
        expect(estilo.statusBarIconBrightness, Brightness.light);

        final fechar = find.byKey(const ValueKey('visualizador-fechar'));
        expect(
          tester.getSize(fechar).height,
          greaterThanOrEqualTo(kMinInteractiveDimension),
        );
        await tester.tap(fechar);
        await tester.pumpAndSettle();

        expect(find.byType(VisualizadorImagem), findsNothing);
        expect(find.byType(FotoPublicacao), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('o botão de fechar tem rótulo para o leitor de tela', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await montar(tester, imagemDeTeste: await imagem(tester, 40, 80));
      await tester.tap(find.byType(FotoPublicacao));
      await tester.pumpAndSettle();

      final fechar = find.bySemanticsLabel('Fechar foto');
      expect(fechar, findsOneWidget);
      final dados = tester.getSemantics(fechar).getSemanticsData();
      expect(dados.flagsCollection.isButton, isTrue);
      expect(dados.hasAction(ui.SemanticsAction.tap), isTrue);
      semantics.dispose();
    });
  });
}
