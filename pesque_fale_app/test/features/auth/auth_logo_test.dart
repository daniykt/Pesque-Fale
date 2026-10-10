import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/presentation/widgets/auth_logo.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<List<Image>> montar(WidgetTester tester, ThemeData tema) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: tema,
        home: const Scaffold(body: Center(child: AuthLogo())),
      ),
    );
    return tester.widgetList<Image>(find.byType(Image)).toList();
  }

  testWidgets('no tema claro mantém as cores originais do logo', (
    tester,
  ) async {
    final imagens = await montar(tester, AppTheme.light);

    expect(imagens, hasLength(2));
    for (final imagem in imagens) {
      expect(imagem.color, isNull);
    }
  });

  testWidgets('no tema escuro pinta o logo com a cor clara do texto', (
    tester,
  ) async {
    final imagens = await montar(tester, AppTheme.dark);

    expect(imagens, hasLength(2));
    for (final imagem in imagens) {
      expect(imagem.color, AppColors.dark.textPrimary);
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