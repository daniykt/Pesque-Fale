import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/chat/presentation/widgets/badge_nao_lidas.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montar(WidgetTester tester, int quantidade) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: BadgeNaoLidas(quantidade: quantidade)),
      ),
    );
  }

  testWidgets('mostra a quantidade quando <= 99', (tester) async {
    await montar(tester, 18);
    expect(find.text('18'), findsOneWidget);
  });

  testWidgets('mostra 99+ quando quantidade > 99', (tester) async {
    await montar(tester, 120);
    expect(find.text('99+'), findsOneWidget);
    expect(find.text('120'), findsNothing);
  });

  testWidgets('mostra exatamente 99 sem sufixo', (tester) async {
    await montar(tester, 99);
    expect(find.text('99'), findsOneWidget);
  });
}
