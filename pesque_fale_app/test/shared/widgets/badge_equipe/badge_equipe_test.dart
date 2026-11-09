import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/shared/widgets/badge_equipe/badge_equipe.dart';
import 'package:pesque_fale_app/shared/widgets/badge_equipe/tipo_badge.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montar(
    WidgetTester tester,
    TipoBadge tipo, {
    ThemeData? tema,
    BadgeTamanho tamanho = BadgeTamanho.md,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: tema ?? AppTheme.light,
        home: Scaffold(
          body: Center(
            child: BadgeEquipe(tipo: tipo, tamanho: tamanho),
          ),
        ),
      ),
    );
  }

  BoxDecoration decoracao(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(BadgeEquipe),
        matching: find.byType(Container),
      ),
    );
    return container.decoration! as BoxDecoration;
  }

  Color corDoTexto(WidgetTester tester, String rotulo) =>
      tester.widget<Text>(find.text(rotulo)).style!.color!;

  testWidgets('dev renderiza DEV em maiusculas', (tester) async {
    await montar(tester, TipoBadge.dev);

    expect(find.text('DEV'), findsOneWidget);
    expect(find.text('Dev'), findsNothing);
  });

  testWidgets('oficial renderiza OFICIAL em maiusculas', (tester) async {
    await montar(tester, TipoBadge.oficial);

    expect(find.text('OFICIAL'), findsOneWidget);
    expect(find.text('Oficial'), findsNothing);
  });

  testWidgets('tooltip do dev tem a mensagem correta e abre no long press', (
    tester,
  ) async {
    await montar(tester, TipoBadge.dev);

    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'Desenvolvedor do Pesque & Fale');
    expect(tooltip.triggerMode, TooltipTriggerMode.longPress);

    await tester.longPress(find.text('DEV'));
    await tester.pumpAndSettle();
    expect(find.text('Desenvolvedor do Pesque & Fale'), findsOneWidget);
  });

  testWidgets('tooltip do oficial tem a mensagem correta', (tester) async {
    await montar(tester, TipoBadge.oficial);

    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'Conta oficial do Pesque & Fale');
  });

  testWidgets('tamanho sm usa fonte 9 e md usa fonte 10', (tester) async {
    await montar(tester, TipoBadge.dev, tamanho: BadgeTamanho.sm);
    expect(tester.widget<Text>(find.text('DEV')).style!.fontSize, 9);

    await montar(tester, TipoBadge.dev);
    expect(tester.widget<Text>(find.text('DEV')).style!.fontSize, 10);
  });

  testWidgets('oficial no claro e solido primary com texto branco', (
    tester,
  ) async {
    await montar(tester, TipoBadge.oficial);

    expect(decoracao(tester).color, AppColors.light.primary);
    expect(corDoTexto(tester, 'OFICIAL'), Colors.white);
  });

  testWidgets('oficial no escuro inverte pra primaryAccent', (tester) async {
    await montar(tester, TipoBadge.oficial, tema: AppTheme.dark);

    expect(decoracao(tester).color, AppColors.dark.primaryAccent);
    expect(corDoTexto(tester, 'OFICIAL'), AppColors.dark.onPrimaryAccent);
  });

  testWidgets('dev e outline translucido em primaryAccent', (tester) async {
    await montar(tester, TipoBadge.dev, tema: AppTheme.dark);

    final accent = AppColors.dark.primaryAccent;
    expect(decoracao(tester).color, accent.withValues(alpha: 0.14));
    expect(corDoTexto(tester, 'DEV'), accent);
  });
}
