import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/assistente/presentation/widgets/botao_ajuda_assistente.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const tooltip = 'Abrir o Pirá, assistente virtual';

  Future<void> montar(WidgetTester tester, {bool compacto = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: const Text('HOME'),
          floatingActionButton: BotaoAjudaAssistente(compacto: compacto),
        ),
        routes: {
          '/assistente': (_) => const Scaffold(body: Text('ASSISTENTE')),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra "Ajuda" e abre o assistente', (tester) async {
    await montar(tester);

    expect(find.text('Ajuda'), findsOneWidget);
    expect(find.byTooltip(tooltip), findsOneWidget);

    await tester.tap(find.text('Ajuda'));
    await tester.pumpAndSettle();

    expect(find.text('ASSISTENTE'), findsOneWidget);
  });

  testWidgets('compacto vira um círculo só com o mascote e abre o assistente', (
    tester,
  ) async {
    await montar(tester, compacto: true);

    expect(find.text('Ajuda'), findsNothing);
    expect(find.byTooltip(tooltip), findsOneWidget);

    final tamanho = tester.getSize(find.byType(FloatingActionButton));
    expect(tamanho.width, tamanho.height);
    expect(tamanho.height, 56);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('ASSISTENTE'), findsOneWidget);
  });

  for (final compacto in [false, true]) {
    testWidgets('alvo de toque adequado (compacto: $compacto)', (tester) async {
      await montar(tester, compacto: compacto);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  }
}
