import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/assistente/presentation/widgets/botao_ajuda_assistente.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('mostra "Ajuda" e abre o assistente', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Text('HOME'),
          floatingActionButton: BotaoAjudaAssistente(),
        ),
        routes: {'/assistente': (_) => const Scaffold(body: Text('ASSISTENTE'))},
      ),
    );

    expect(find.text('Ajuda'), findsOneWidget);
    expect(find.byTooltip('Abrir o Pirá, assistente virtual'), findsOneWidget);

    await tester.tap(find.text('Ajuda'));
    await tester.pumpAndSettle();

    expect(find.text('ASSISTENTE'), findsOneWidget);
  });
}