import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/assistente/presentation/widgets/mascote_pira.dart';
import 'package:pesque_fale_app/features/auth/presentation/widgets/auth_logo.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montar(WidgetTester tester, ThemeData tema, Widget mascote) =>
      tester.pumpWidget(
        MaterialApp(
          theme: tema,
          home: Scaffold(body: Center(child: mascote)),
        ),
      );

  testWidgets('no tema claro mostra o peixe original', (tester) async {
    await montar(tester, AppTheme.light, const MascotePira());

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(ColorFiltered), findsNothing);
  });

  testWidgets('no tema escuro deixa o peixe claro, com os detalhes', (
    tester,
  ) async {
    await montar(tester, AppTheme.dark, const MascotePira());

    final filtrado = tester.widget<ColorFiltered>(find.byType(ColorFiltered));
    expect(
      filtrado.colorFilter,
      AuthLogo.filtroModoEscuro(AppColors.dark.textPrimary),
    );
  });

  testWidgets('cor informada vale nos dois temas', (tester) async {
    await montar(
      tester,
      AppTheme.light,
      const MascotePira(cor: Colors.white),
    );

    final filtrado = tester.widget<ColorFiltered>(find.byType(ColorFiltered));
    expect(filtrado.colorFilter, AuthLogo.filtroModoEscuro(Colors.white));
  });

  testWidgets('balança enquanto está animando e para depois', (tester) async {
    await montar(tester, AppTheme.light, const MascotePira(animando: true));

    await tester.pump(const Duration(milliseconds: 350));
    final deslocamento = tester
        .widget<Transform>(
          find.descendant(
            of: find.byType(MascotePira),
            matching: find.byType(Transform),
          ),
        )
        .transform
        .getTranslation()
        .y;
    expect(deslocamento, lessThan(0));

    await montar(tester, AppTheme.light, const MascotePira());
    await tester.pumpAndSettle();
    final parado = tester
        .widget<Transform>(
          find.descendant(
            of: find.byType(MascotePira),
            matching: find.byType(Transform),
          ),
        )
        .transform
        .getTranslation()
        .y;
    expect(parado, 0);
  });

  testWidgets('não é lido pelo leitor de tela', (tester) async {
    await montar(tester, AppTheme.light, const MascotePira());

    expect(
      find.ancestor(
        of: find.byType(Image),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
  });
}