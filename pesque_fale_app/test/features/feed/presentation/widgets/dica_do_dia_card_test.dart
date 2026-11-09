import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/feed/domain/dicas_de_pesca.dart';
import 'package:pesque_fale_app/features/feed/presentation/widgets/dica_do_dia_card.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final (nomeTema, criarTema) in [
    ('claro', () => AppTheme.light),
    ('escuro', () => AppTheme.dark),
  ]) {
    group('tema $nomeTema', () {
      Future<void> montar(WidgetTester tester, DateTime data) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: criarTema(),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: DicaDoDiaCard(data: data),
              ),
            ),
          ),
        );
      }

      testWidgets('mostra a dica do dia informado', (tester) async {
        await montar(tester, DateTime(2026, 1, 3));

        expect(find.text('Dica do dia'), findsOneWidget);
        expect(find.text(dicasDePesca[2]), findsOneWidget);
        expect(find.textContaining('Tucunaré ataca melhor'), findsNothing);
      });

      testWidgets('outro dia mostra outra dica', (tester) async {
        await montar(tester, DateTime(2026, 1, 4));

        expect(find.text(dicasDePesca[3]), findsOneWidget);
        expect(find.text(dicasDePesca[2]), findsNothing);
      });

      testWidgets('a dica mais longa cabe em 360dp com fonte 1.3', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final maisLonga = dicasDePesca.reduce(
          (a, b) => a.length >= b.length ? a : b,
        );
        final indice = dicasDePesca.indexOf(maisLonga);

        await montar(tester, DateTime(2026, 1, 1 + indice));

        expect(find.text(maisLonga), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
