import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/perfil/presentation/widgets/perfil_opcoes_sheet.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montarWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => PerfilOpcoesSheet.show(context),
              child: const Text('abrir'),
            ),
          ),
        ),
        routes: {
          '/configuracoes': (_) =>
              const Scaffold(body: Text('Configurações')),
          '/sobre': (_) => const Scaffold(body: Text('Sobre Nós')),
        },
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('renderiza Sobre Nos e Configuracoes, nada mais', (
    tester,
  ) async {
    await montarWidget(tester);

    expect(find.text('Sobre Nós'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.text('Reiniciar Tour'), findsNothing);
    expect(find.text('Sair'), findsNothing);
  });

  testWidgets('tap em Configuracoes navega para /configuracoes', (
    tester,
  ) async {
    await montarWidget(tester);

    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();

    expect(find.byType(PerfilOpcoesSheet), findsNothing);
    expect(find.text('Configurações'), findsOneWidget);
  });
}
