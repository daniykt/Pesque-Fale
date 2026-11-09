import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/onboarding/presentation/widgets/onboarding_botao_principal.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montarWidget(
    WidgetTester tester, {
    required VoidCallback? onPressed,
    bool loading = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: OnboardingBotaoPrincipal(
            label: 'Continuar',
            onPressed: onPressed,
            loading: loading,
          ),
        ),
      ),
    );
  }

  testWidgets('renderiza texto e icone quando loading e false', (
    tester,
  ) async {
    await montarWidget(tester, onPressed: () {});

    expect(find.text('Continuar'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renderiza CircularProgressIndicator quando loading e true', (
    tester,
  ) async {
    await montarWidget(tester, onPressed: () {}, loading: true);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Continuar'), findsNothing);
  });

  testWidgets('onPressed e chamado no tap', (tester) async {
    var chamado = false;
    await montarWidget(tester, onPressed: () => chamado = true);

    await tester.tap(find.byType(OnboardingBotaoPrincipal));
    expect(chamado, isTrue);
  });

  testWidgets('onPressed nulo desabilita o botao', (tester) async {
    await montarWidget(tester, onPressed: null);

    final botao = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(botao.onPressed, isNull);
  });
}
