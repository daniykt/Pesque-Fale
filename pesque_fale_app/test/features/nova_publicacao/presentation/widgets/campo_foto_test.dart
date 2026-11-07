import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/nova_publicacao/presentation/widgets/campo_foto.dart';

final _pngTransparente = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final (nomeTema, criarTema) in [
    ('claro', () => AppTheme.light),
    ('escuro', () => AppTheme.dark),
  ]) {
    group('tema $nomeTema', () {
      Future<void> montar(
        WidgetTester tester, {
        Uint8List? foto,
        VoidCallback? onRemover,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: criarTema(),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: CampoFoto(
                  foto: foto,
                  onEscolher: () {},
                  onRemover: onRemover ?? () {},
                ),
              ),
            ),
          ),
        );
      }

      testWidgets('o botão de remover foto tem alvo de pelo menos 48', (
        tester,
      ) async {
        var removeu = 0;
        await montar(
          tester,
          foto: _pngTransparente,
          onRemover: () => removeu++,
        );

        final botao = find.byTooltip('Remover foto');
        expect(botao, findsOneWidget);
        final tamanho = tester.getSize(find.byType(IconButton));
        expect(tamanho.width, greaterThanOrEqualTo(48));
        expect(tamanho.height, greaterThanOrEqualTo(48));

        await tester.tap(botao);
        expect(removeu, 1);
      });

      testWidgets('sem foto, o estado vazio cabe em 360dp com fonte 1.3', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await montar(tester);

        expect(find.text('Clique para adicionar uma foto'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
