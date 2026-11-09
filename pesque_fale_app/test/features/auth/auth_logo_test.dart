import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/presentation/widgets/auth_logo.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montar(WidgetTester tester, ThemeData tema) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: tema,
        home: const Scaffold(body: Center(child: AuthLogo())),
      ),
    );
  }

  List<Image> imagens(WidgetTester tester) =>
      tester.widgetList<Image>(find.byType(Image)).toList();

  testWidgets('no tema claro mostra o logo original, sem filtro', (
    tester,
  ) async {
    await montar(tester, AppTheme.light);

    expect(imagens(tester), hasLength(2));
    expect(find.byType(ColorFiltered), findsNothing);
    for (final imagem in imagens(tester)) {
      expect(imagem.color, isNull);
    }
  });

  testWidgets('no tema escuro aplica o filtro com a cor clara do texto', (
    tester,
  ) async {
    await montar(tester, AppTheme.dark);

    final filtrado = tester.widget<ColorFiltered>(find.byType(ColorFiltered));
    expect(
      filtrado.colorFilter,
      AuthLogo.filtroModoEscuro(AppColors.dark.textPrimary),
    );
    expect(
      find.descendant(
        of: find.byType(ColorFiltered),
        matching: find.byType(Image),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('no tema escuro não pinta as imagens por cima dos detalhes', (
    tester,
  ) async {
    await montar(tester, AppTheme.dark);

    for (final imagem in imagens(tester)) {
      expect(imagem.color, isNull);
    }
  });

  testWidgets('não é lido pelo leitor de tela', (tester) async {
    await montar(tester, AppTheme.light);

    expect(
      find.ancestor(
        of: find.byType(Image).first,
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
  });
}