import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/tour/domain/tour_passo.dart';
import 'package:pesque_fale_app/features/tour/presentation/widgets/tour_card.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const passo = TourPasso(
    index: 2,
    titulo: 'Pesquisa',
    descricao: 'Pesquise pontos de pesca perto de você.',
    abaAlvo: 1,
  );

  Future<void> montarWidget(
    WidgetTester tester, {
    required TourPasso passo,
    int total = 7,
    VoidCallback? onAnterior,
    VoidCallback? onProximo,
    VoidCallback? onPular,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TourCard(
            passo: passo,
            total: total,
            onAnterior: onAnterior ?? () {},
            onProximo: onProximo ?? () {},
            onPular: onPular ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('renderiza titulo, descricao e progresso do passo', (
    tester,
  ) async {
    await montarWidget(tester, passo: passo);

    expect(find.text('Pesquisa'), findsOneWidget);
    expect(
      find.text('Pesquise pontos de pesca perto de você.'),
      findsOneWidget,
    );
    expect(find.text('Passo 3 de 7'), findsOneWidget);
    expect(find.text('43%'), findsOneWidget);
    expect(find.text('Próximo'), findsOneWidget);
  });

  testWidgets('mostra "Começar! 🎣" no ultimo passo', (tester) async {
    await montarWidget(
      tester,
      passo: const TourPasso(
        index: 6,
        titulo: 'Menu de Opções',
        descricao: 'Configurações do app.',
        abaAlvo: 4,
      ),
      total: 7,
    );

    expect(find.text('Começar! 🎣'), findsOneWidget);
    expect(find.text('Próximo'), findsNothing);
  });

  testWidgets('botao Anterior fica desabilitado no primeiro passo', (
    tester,
  ) async {
    await montarWidget(
      tester,
      passo: const TourPasso(
        index: 0,
        titulo: 'Bem-vindo!',
        descricao: 'Vamos comecar.',
        abaAlvo: 0,
      ),
    );

    final botao = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Anterior'),
    );
    expect(botao.onPressed, isNull);
  });

  testWidgets('onProximo e chamado ao tocar em Próximo', (tester) async {
    var chamado = false;
    await montarWidget(tester, passo: passo, onProximo: () => chamado = true);

    await tester.tap(find.text('Próximo'));
    expect(chamado, isTrue);
  });

  testWidgets('onAnterior e chamado ao tocar em Anterior', (tester) async {
    var chamado = false;
    await montarWidget(
      tester,
      passo: passo,
      onAnterior: () => chamado = true,
    );

    await tester.tap(find.text('Anterior'));
    expect(chamado, isTrue);
  });

  testWidgets('onPular e chamado ao tocar em Pular', (tester) async {
    var chamado = false;
    await montarWidget(tester, passo: passo, onPular: () => chamado = true);

    await tester.tap(find.text('Pular'));
    expect(chamado, isTrue);
  });
}
