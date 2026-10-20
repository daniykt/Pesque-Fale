import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/shared/widgets/app_snackbar.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montar(
    WidgetTester tester,
    void Function(BuildContext context) aoTocar,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => aoTocar(context),
              child: const Text('MOSTRAR'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('MOSTRAR'));
    await tester.pumpAndSettle();
  }

  final variacoes = <String, void Function(BuildContext)>{
    'erro': (c) => AppSnackbar.showError(c, 'Mensagem'),
    'sucesso': (c) => AppSnackbar.showSuccess(c, 'Mensagem'),
    'aviso': (c) => AppSnackbar.showWarning(c, 'Mensagem'),
    'informação': (c) => AppSnackbar.showInfo(c, 'Mensagem'),
  };

  for (final MapEntry(key: tipo, value: mostrar) in variacoes.entries) {
    testWidgets('$tipo: fecha na hora ao tocar no X', (tester) async {
      await montar(tester, mostrar);
      expect(find.text('Mensagem'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Mensagem'), findsNothing);
    });

    testWidgets('$tipo: some sozinha depois do tempo', (tester) async {
      await montar(tester, mostrar);
      expect(find.text('Mensagem'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.text('Mensagem'), findsNothing);
    });
  }

  testWidgets('fecha no X mesmo depois que a tela que a mostrou saiu', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        AppSnackbar.showSuccess(context, 'Publicação enviada!');
                      },
                      child: const Text('PUBLICAR'),
                    ),
                  ),
                ),
              ),
              child: const Text('ABRIR'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PUBLICAR'));
    await tester.pumpAndSettle();
    expect(find.text('PUBLICAR'), findsNothing);
    expect(find.text('Publicação enviada!'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Publicação enviada!'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uma mensagem nova substitui a anterior', (tester) async {
    var vezes = 0;
    await montar(tester, (c) {
      vezes++;
      if (vezes == 1) {
        AppSnackbar.showError(c, 'Primeira');
      } else {
        AppSnackbar.showSuccess(c, 'Segunda');
      }
    });
    expect(find.text('Primeira'), findsOneWidget);

    await tester.tap(find.text('MOSTRAR'));
    await tester.pumpAndSettle();

    expect(find.text('Primeira'), findsNothing);
    expect(find.text('Segunda'), findsOneWidget);
  });
}