import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/onboarding/domain/onboarding_etapa.dart';
import 'package:pesque_fale_app/features/onboarding/presentation/widgets/onboarding_barra_progresso.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montarWidget(
    WidgetTester tester,
    OnboardingEtapa etapaAtual,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: OnboardingBarraProgresso(etapaAtual: etapaAtual),
        ),
      ),
    );
  }

  Color? corDoNumero(WidgetTester tester, int numero) {
    final text = tester.widget<Text>(find.text('$numero'));
    return text.style?.color;
  }

  testWidgets('renderiza os 7 circulos numerados', (tester) async {
    await montarWidget(tester, OnboardingEtapa.boasVindas);

    for (var numero = 1; numero <= 7; numero++) {
      expect(find.text('$numero'), findsOneWidget);
    }
  });

  testWidgets(
    'circulo da etapa atual esta preenchido e os posteriores nao',
    (tester) async {
      await montarWidget(tester, OnboardingEtapa.nomeLocalizacao);
      final colors = AppColors.light;

      expect(corDoNumero(tester, 1), Colors.white);
      expect(corDoNumero(tester, 2), Colors.white);
      expect(corDoNumero(tester, 3), Colors.white);
      expect(corDoNumero(tester, 4), colors.textSecondary);
      expect(corDoNumero(tester, 7), colors.textSecondary);
    },
  );

  testWidgets('etapa sucesso preenche todos os 7 circulos', (tester) async {
    await montarWidget(tester, OnboardingEtapa.sucesso);

    for (var numero = 1; numero <= 7; numero++) {
      expect(corDoNumero(tester, numero), Colors.white);
    }
  });
}
