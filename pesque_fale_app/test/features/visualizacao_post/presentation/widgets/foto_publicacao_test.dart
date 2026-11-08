import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/features/visualizacao_post/presentation/widgets/foto_publicacao.dart';
import 'package:pesque_fale_app/shared/widgets/imagem_placeholder.dart';

/// Cores do app sem GoogleFonts: as fontes não são empacotadas nos testes e,
/// com o runAsync que decodifica a imagem, o carregamento delas falha e
/// derruba o teste (o mesmo motivo do crop_imagem_page_test).
final _tema = ThemeData(extensions: const [AppColors.light]);

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

  /// Monta a foto em 360 de largura. Sem [imagemDeTeste], usa a URL de rede,
  /// que falha no teste.
  Future<void> montar(
    WidgetTester tester, {
    required ImageProvider? imagemDeTeste,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _tema,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 360,
              child: FotoPublicacao(
                url: 'https://res.cloudinary.com/demo/image/upload/v1/foto.jpg',
                imagem: imagemDeTeste,
              ),
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

  Finder imagemDaFoto() => find.descendant(
    of: find.byType(FotoPublicacao),
    matching: find.byType(Image),
  );

  for (final (nome, largura, altura) in [
    ('em pé', 40, 80),
    ('deitada', 80, 40),
    ('quadrada', 50, 50),
  ]) {
    testWidgets('foto $nome sai no quadro 1:1 de 360×360, com cover', (
      tester,
    ) async {
      await montar(
        tester,
        imagemDeTeste: await imagem(tester, largura, altura),
      );

      expect(find.byType(ImagemCarregando), findsNothing);
      expect(tester.getSize(find.byType(FotoPublicacao)), const Size(360, 360));
      expect(tester.getSize(imagemDaFoto()), const Size(360, 360));
      expect(tester.widget<Image>(imagemDaFoto()).fit, BoxFit.cover);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('foto que falha mostra Imagem indisponível no quadro 1:1', (
    tester,
  ) async {
    await montar(tester, imagemDeTeste: null);

    expect(find.byType(ImagemIndisponivel), findsOneWidget);
    expect(
      tester.getSize(find.byType(ImagemIndisponivel)),
      const Size(360, 360),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pede ao Cloudinary a foto cortada em 1080×1080', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _tema,
        home: const Scaffold(
          body: FotoPublicacao(
            url: 'https://res.cloudinary.com/demo/image/upload/v1/foto.jpg',
          ),
        ),
      ),
    );

    expect(
      (tester.widget<Image>(imagemDaFoto()).image as NetworkImage).url,
      'https://res.cloudinary.com/demo/image/upload/'
      'c_fill,w_1080,h_1080,q_auto,f_auto/v1/foto.jpg',
    );
  });

  testWidgets('sem toque e sem selo: a foto não abre nada', (tester) async {
    await montar(tester, imagemDeTeste: await imagem(tester, 40, 80));

    expect(
      find.descendant(
        of: find.byType(FotoPublicacao),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(FotoPublicacao),
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
    );
    expect(find.text('Toque para ampliar'), findsNothing);

    await tester.tap(find.byType(FotoPublicacao), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(FotoPublicacao), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('o leitor de tela lê só uma imagem: Foto da publicação', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await montar(tester, imagemDeTeste: await imagem(tester, 40, 80));

    final foto = find.bySemanticsLabel('Foto da publicação');
    expect(foto, findsOneWidget);
    final dados = tester.getSemantics(foto).getSemanticsData();
    expect(dados.flagsCollection.isImage, isTrue);
    expect(dados.flagsCollection.isButton, isFalse);
    expect(dados.hasAction(ui.SemanticsAction.tap), isFalse);
    semantics.dispose();
  });
}
