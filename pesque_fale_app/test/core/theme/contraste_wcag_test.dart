import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';

/// Razão de contraste WCAG 2.1 entre duas cores opacas.
double contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final claro = la > lb ? la : lb;
  final escuro = la > lb ? lb : la;
  return (claro + 0.05) / (escuro + 0.05);
}

/// Compõe [cor] com [alpha] sobre o [fundo] real.
Color sobre(Color cor, double alpha, Color fundo) =>
    Color.alphaBlend(cor.withValues(alpha: alpha), fundo);

String _hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

void _verifica(
  String tema,
  String par,
  Color frente,
  Color fundo,
  double minimo,
) {
  final medido = contraste(frente, fundo);
  expect(
    medido,
    greaterThanOrEqualTo(minimo),
    reason:
        '[$tema] $par (${_hex(frente)} sobre ${_hex(fundo)}): '
        '${medido.toStringAsFixed(2)}:1, mínimo $minimo:1',
  );
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  final temas = <String, ThemeData Function()>{
    'claro': () => AppTheme.light,
    'escuro': () => AppTheme.dark,
  };

  for (final MapEntry(key: nome, value: construir) in temas.entries) {
    group('tema $nome', () {
      late ThemeData tema;
      late AppColors c;
      late ColorScheme s;

      // O tema é montado dentro do testWidgets para que o carregamento
      // assíncrono das fontes fique na zona de teste.
      void caso(String descricao, void Function() corpo) {
        testWidgets(descricao, (tester) async {
          tema = construir();
          c = tema.extension<AppColors>()!;
          s = tema.colorScheme;
          corpo();
        });
      }

      caso('texto e destaque sobre background, surface e surfaceVariant', () {
        final fundos = {
          'background': c.background,
          'surface': c.surface,
          'surfaceVariant': c.surfaceVariant,
        };
        final frentes = {
          'primaryAccent': c.primaryAccent,
          'textPrimary': c.textPrimary,
          'textSecondary': c.textSecondary,
        };
        for (final f in frentes.entries) {
          for (final b in fundos.entries) {
            _verifica(nome, '${f.key} / ${b.key}', f.value, b.value, 4.5);
          }
        }
      });

      caso('navInactive sobre surface', () {
        _verifica(nome, 'navInactive / surface', c.navInactive, c.surface, 4.5);
      });

      caso('danger e success sobre background e surface', () {
        _verifica(nome, 'danger / background', c.danger, c.background, 4.5);
        _verifica(nome, 'danger / surface', c.danger, c.surface, 4.5);
        _verifica(nome, 'success / background', c.success, c.background, 4.5);
        _verifica(nome, 'success / surface', c.success, c.surface, 4.5);
      });

      caso('danger sobre fundo de diálogo', () {
        _verifica(
          nome,
          'danger / surfaceContainerHigh',
          c.danger,
          s.surfaceContainerHigh,
          4.5,
        );
      });

      caso('success sobre chip "Disponível"', () {
        _verifica(
          nome,
          'success / success 15% sobre background',
          c.success,
          sobre(c.success, 0.15, c.background),
          4.5,
        );
      });

      caso('branco sobre primary', () {
        _verifica(nome, 'branco / primary', Colors.white, c.primary, 4.5);
      });

      caso('onPrimary sobre primary do ColorScheme', () {
        _verifica(nome, 's.onPrimary / s.primary', s.onPrimary, s.primary, 4.5);
      });

      caso('primary do ColorScheme sobre surface e surfaceVariant', () {
        _verifica(nome, 's.primary / surface', s.primary, c.surface, 3.0);
        _verifica(
          nome,
          's.primary / surfaceVariant',
          s.primary,
          c.surfaceVariant,
          3.0,
        );
      });

      caso('frente sobre fundo do filledButtonTheme', () {
        final estilo = tema.filledButtonTheme.style!;
        final frente = estilo.foregroundColor!.resolve(<WidgetState>{})!;
        final fundo = estilo.backgroundColor!.resolve(<WidgetState>{})!;
        _verifica(nome, 'FilledButton frente / fundo', frente, fundo, 4.5);
      });

      caso('tokens on* sobre seus preenchimentos', () {
        _verifica(
          nome,
          'onPrimaryAccent / primaryAccent',
          c.onPrimaryAccent,
          c.primaryAccent,
          4.5,
        );
        _verifica(nome, 'onSuccess / success', c.onSuccess, c.success, 4.5);
        _verifica(nome, 'onDanger / danger', c.onDanger, c.danger, 4.5);
        _verifica(nome, 'onWarning / warning', c.onWarning, c.warning, 4.5);
      });

      caso('rating sobre background', () {
        _verifica(nome, 'rating / background', c.rating, c.background, 3.0);
      });

      caso('primaryAccent sobre tag', () {
        _verifica(
          nome,
          'primaryAccent / primaryAccent 15% sobre surface',
          c.primaryAccent,
          sobre(c.primaryAccent, 0.15, c.surface),
          4.5,
        );
      });

      caso('outline do ColorScheme sobre surface', () {
        _verifica(nome, 's.outline / surface', s.outline, c.surface, 3.0);
      });

      caso('texto secundário da AppBar sobre primary', () {
        _verifica(
          nome,
          'branco 72% sobre primary / primary',
          sobre(Colors.white, 0.72, c.primary),
          c.primary,
          4.5,
        );
      });
    });
  }
}
