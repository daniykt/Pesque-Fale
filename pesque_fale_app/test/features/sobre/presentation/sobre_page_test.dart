import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/sobre/presentation/sobre_page.dart';

void main() {
  testWidgets('SobrePage renderiza sem crashar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SobrePage()),
    );

    expect(find.text('Sobre Nós'), findsOneWidget);
  });

  testWidgets('SobrePage mostra todos os membros do time', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SobrePage()),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Danilo'), findsOneWidget);
    expect(find.text('Felipe'), findsOneWidget);
    expect(find.text('Rebeca'), findsOneWidget);
  });
}
