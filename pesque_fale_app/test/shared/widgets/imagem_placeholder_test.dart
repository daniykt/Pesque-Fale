import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/shared/widgets/imagem_placeholder.dart';

double _contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (claro, escuro) = la > lb ? (la, lb) : (lb, la);
  return (claro + 0.05) / (escuro + 0.05);
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final (nomeTema, criarTema) in [
    ('claro', () => AppTheme.light),
    ('escuro', () => AppTheme.dark),
  ]) {
    group('tema $nomeTema', () {
      late ThemeData tema;
      late AppColors colors;

      Future<void> montar(WidgetTester tester, Widget filho) async {
        tema = criarTema();
        colors = tema.extension<AppColors>()!;
        await tester.pumpWidget(
          MaterialApp(
            theme: tema,
            home: Scaffold(
              body: Center(
                child: SizedBox(width: 300, height: 300, child: filho),
              ),
            ),
          ),
        );
      }

      testWidgets('carregando: fundo distinto do fundo da tela e ícone fixo', (
        tester,
      ) async {
        await montar(tester, const ImagemCarregando());

        final fundo = tester
            .widget<ColoredBox>(
              find.descendant(
                of: find.byType(ImagemCarregando),
                matching: find.byType(ColoredBox),
              ),
            )
            .color;
        expect(fundo, isNot(colors.background));
        expect(fundo, isNot(colors.surfaceVariant));

        final icone = find.byIcon(Icons.image_outlined);
        expect(icone, findsOneWidget);
        final pulso = find.descendant(
          of: find.byType(ImagemCarregando),
          matching: find.byType(FadeTransition),
        );
        expect(pulso, findsOneWidget);
        expect(
          find.descendant(of: pulso, matching: icone),
          findsNothing,
          reason: 'só o fundo pulsa; o ícone mantém o contraste',
        );
        expect(
          _contraste(tester.widget<Icon>(icone).color!, fundo),
          greaterThanOrEqualTo(3),
        );
        expect(find.bySemanticsLabel('Carregando imagem'), findsOneWidget);
      });

      testWidgets('indisponível: ícone, texto e contraste legível', (
        tester,
      ) async {
        await montar(tester, const ImagemIndisponivel());

        final fundo =
            tester
                .widget<Container>(
                  find.descendant(
                    of: find.byType(ImagemIndisponivel),
                    matching: find.byType(Container),
                  ),
                )
                .color ??
            Colors.transparent;
        expect(fundo, isNot(colors.background));
        expect(fundo, isNot(colors.surfaceVariant));

        final icone = tester.widget<Icon>(
          find.byIcon(Icons.broken_image_outlined),
        );
        expect(_contraste(icone.color!, fundo), greaterThanOrEqualTo(3));
        expect(find.text('Imagem indisponível'), findsOneWidget);
        expect(find.bySemanticsLabel('Imagem indisponível'), findsOneWidget);
      });

      testWidgets('indisponível sem texto para espaços pequenos', (
        tester,
      ) async {
        await montar(tester, const ImagemIndisponivel(mostrarTexto: false));

        expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
        expect(find.text('Imagem indisponível'), findsNothing);
        expect(find.bySemanticsLabel('Imagem indisponível'), findsOneWidget);
      });
    });
  }
}
