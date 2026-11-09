import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/shared/widgets/crop_imagem/crop_imagem_helper.dart';
import 'package:pesque_fale_app/shared/widgets/crop_imagem/crop_imagem_page.dart';
import 'package:pesque_fale_app/shared/widgets/crop_imagem/modo_crop.dart';

/// PNG sólido em memória — pequeno pra o parse do Crop ser rápido no teste.
Uint8List _png({int largura = 64, int altura = 48, bool transparente = false}) {
  final imagem = img.Image(
    width: largura,
    height: altura,
    numChannels: transparente ? 4 : 3,
  );
  img.fill(
    imagem,
    color: transparente
        ? img.ColorRgba8(0, 0, 0, 0)
        : img.ColorRgb8(30, 120, 200),
  );
  return img.encodePng(imagem);
}

/// Tema com as cores do app mas sem GoogleFonts, pro teste ponta a ponta.
///
/// As fontes não são empacotadas nos testes: com runAsync longo (parse e
/// recorte em isolate) o google_fonts chega a tentar carregá-las de
/// verdade, falha e derruba o teste. Os demais testes usam o AppTheme.light.
final _temaSemFontes = ThemeData(extensions: const [AppColors.light]);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montarPagina(WidgetTester tester, ModoCrop modo) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CropImagemPage(bytesOriginais: _png(), modo: modo),
      ),
    );
  }

  /// Abre a página via helper (como os widgets de perfil fazem) e devolve um
  /// getter pro que ela devolveu no pop.
  Future<({bool fechou, Uint8List? bytes}) Function()> abrirViaHelper(
    WidgetTester tester,
    ModoCrop modo, {
    ThemeData? tema,
  }) async {
    var fechou = false;
    Uint8List? bytes;
    await tester.pumpWidget(
      MaterialApp(
        theme: tema ?? AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                bytes = await CropImagemHelper.abrirCrop(
                  context,
                  bytes: _png(),
                  modo: modo,
                );
                fechou = true;
              },
              child: const Text('ABRIR'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ABRIR'));
    // Sem pumpAndSettle: o spinner do Crop gira até a imagem carregar.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return () => (fechou: fechou, bytes: bytes);
  }

  /// Dá tempo real (runAsync) pros isolates e pumpa fora dele até [condicao].
  Future<void> esperar(WidgetTester tester, bool Function() condicao) async {
    for (var tentativa = 0; !condicao(); tentativa++) {
      if (tentativa == 500) fail('condição não atingida a tempo');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  TextButton botaoConfirmar(WidgetTester tester) =>
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Confirmar'));

  group('CropImagemPage - configuracao do Crop', () {
    testWidgets('modo avatar usa area circular 1:1', (tester) async {
      await montarPagina(tester, ModoCrop.avatar);

      final crop = tester.widget<Crop>(find.byType(Crop));
      expect(crop.withCircleUi, isTrue);
      expect(crop.aspectRatio, 1.0);
      expect(crop.interactive, isTrue);
      expect(find.text('Ajustar foto'), findsOneWidget);
    });

    testWidgets('modo banner usa area retangular 16:9', (tester) async {
      await montarPagina(tester, ModoCrop.banner);

      final crop = tester.widget<Crop>(find.byType(Crop));
      expect(crop.withCircleUi, isFalse);
      expect(crop.aspectRatio, 16 / 9);
      expect(crop.interactive, isTrue);
      expect(find.text('Ajustar banner'), findsOneWidget);
    });

    testWidgets('AppBar tem Cancelar e Confirmar', (tester) async {
      await montarPagina(tester, ModoCrop.avatar);

      expect(find.byTooltip('Cancelar'), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.close), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Confirmar'), findsOneWidget);
    });

    testWidgets('Confirmar fica desabilitado ate a imagem carregar', (
      tester,
    ) async {
      await montarPagina(tester, ModoCrop.avatar);

      expect(botaoConfirmar(tester).onPressed, isNull);
    });
  });

  group('CropImagemPage - resultado', () {
    testWidgets('Cancelar fecha devolvendo null', (tester) async {
      final resultado = await abrirViaHelper(tester, ModoCrop.avatar);

      await tester.tap(find.byTooltip('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(CropImagemPage), findsNothing);
      expect(resultado().fechou, isTrue);
      expect(resultado().bytes, isNull);
    });

    testWidgets('Confirmar devolve JPEG no tamanho do modo', (tester) async {
      final resultado = await abrirViaHelper(
        tester,
        ModoCrop.banner,
        tema: _temaSemFontes,
      );

      // Parse da imagem roda em isolate (compute) — precisa de tempo real.
      await esperar(tester, () => botaoConfirmar(tester).onPressed != null);

      await tester.tap(find.widgetWithText(TextButton, 'Confirmar'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Recorte + redimensionamento também rodam em isolate.
      await esperar(tester, () => resultado().fechou);
      await tester.pumpAndSettle();

      final bytes = resultado().bytes;
      expect(bytes, isNotNull);
      final saida = img.decodeJpg(bytes!);
      expect(saida, isNotNull);
      expect(saida!.width, 1600);
      expect(saida.height, 900);
      expect(find.byType(CropImagemPage), findsNothing);
    });
  });

  group('redimensionarRecorte', () {
    test('gera JPEG 512x512 no modo avatar', () {
      final bytes = redimensionarRecorte((
        _png(largura: 300, altura: 300),
        512,
        512,
      ));

      final saida = img.decodeImage(bytes!)!;
      expect(img.findFormatForData(bytes), img.ImageFormat.jpg);
      expect(saida.width, 512);
      expect(saida.height, 512);
    });

    test('gera JPEG 1600x900 no modo banner', () {
      final bytes = redimensionarRecorte((
        _png(largura: 3200, altura: 1800),
        1600,
        900,
      ));

      final saida = img.decodeImage(bytes!)!;
      expect(saida.width, 1600);
      expect(saida.height, 900);
    });

    test('PNG transparente vira fundo branco, nao preto', () {
      final bytes = redimensionarRecorte((
        _png(largura: 16, altura: 16, transparente: true),
        16,
        16,
      ));

      final pixel = img.decodeJpg(bytes!)!.getPixel(8, 8);
      expect(pixel.r, greaterThan(240));
      expect(pixel.g, greaterThan(240));
      expect(pixel.b, greaterThan(240));
    });

    test('devolve null quando os bytes nao sao imagem', () {
      expect(
        redimensionarRecorte((Uint8List.fromList([1, 2, 3]), 512, 512)),
        isNull,
      );
    });
  });
}
