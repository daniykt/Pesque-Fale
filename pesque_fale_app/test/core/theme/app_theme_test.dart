import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';

Color? _corDoTextButton(ThemeData tema) =>
    tema.textButtonTheme.style?.foregroundColor?.resolve(<WidgetState>{});

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('no tema claro, botões de texto usam a cor primária', (
    tester,
  ) async {
    expect(_corDoTextButton(AppTheme.light), AppColors.light.primary);
  });

  testWidgets('no tema escuro, botões de texto usam a cor de destaque clara', (
    tester,
  ) async {
    expect(_corDoTextButton(AppTheme.dark), AppColors.dark.primaryAccent);
  });
}