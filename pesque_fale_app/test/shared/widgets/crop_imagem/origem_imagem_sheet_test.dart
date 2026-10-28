import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/shared/widgets/crop_imagem/origem_imagem_sheet.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  /// Abre o sheet e devolve um getter pro resultado do `show`.
  Future<ImageSource? Function()> abrirSheet(WidgetTester tester) async {
    ImageSource? resultado;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                resultado = await OrigemImagemSheet.show(context);
              },
              child: const Text('ABRIR'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle();
    return () => resultado;
  }

  testWidgets('mostra as opcoes de camera e galeria', (tester) async {
    await abrirSheet(tester);

    expect(find.text('Tirar foto'), findsOneWidget);
    expect(find.text('Escolher da galeria'), findsOneWidget);
  });

  testWidgets('"Tirar foto" devolve ImageSource.camera', (tester) async {
    final resultado = await abrirSheet(tester);

    await tester.tap(find.text('Tirar foto'));
    await tester.pumpAndSettle();

    expect(resultado(), ImageSource.camera);
    expect(find.text('Tirar foto'), findsNothing);
  });

  testWidgets('"Escolher da galeria" devolve ImageSource.gallery', (
    tester,
  ) async {
    final resultado = await abrirSheet(tester);

    await tester.tap(find.text('Escolher da galeria'));
    await tester.pumpAndSettle();

    expect(resultado(), ImageSource.gallery);
  });

  testWidgets('fechar sem escolher devolve null', (tester) async {
    final resultado = await abrirSheet(tester);

    // Toque na barreira, fora do sheet.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text('Tirar foto'), findsNothing);
    expect(resultado(), isNull);
  });
}
