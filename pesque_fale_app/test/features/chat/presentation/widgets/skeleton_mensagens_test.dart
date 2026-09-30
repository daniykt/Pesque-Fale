import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/chat/presentation/widgets/skeleton_mensagens.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montar(WidgetTester tester, {ThemeData? tema}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: tema ?? AppTheme.light,
        home: const Scaffold(body: SkeletonMensagens()),
      ),
    );
    await tester.pump();
  }

  Iterable<Container> bolhas(WidgetTester tester) => tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(SkeletonMensagens),
          matching: find.byType(Container),
        ),
      )
      .where((c) => c.decoration is BoxDecoration);

  testWidgets('mostra uma bolha para cada item do skeleton', (tester) async {
    await montar(tester);

    expect(bolhas(tester), hasLength(SkeletonMensagens.bolhas.length));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('alterna bolhas recebidas e enviadas', (tester) async {
    await montar(tester);

    final alinhamentos = tester
        .widgetList<Align>(
          find.descendant(
            of: find.byType(SkeletonMensagens),
            matching: find.byType(Align),
          ),
        )
        .map((a) => a.alignment)
        .toList();

    expect(alinhamentos.where((a) => a == Alignment.centerLeft), hasLength(3));
    expect(alinhamentos.where((a) => a == Alignment.centerRight), hasLength(3));
  });

  testWidgets('anuncia o carregamento para leitores de tela', (tester) async {
    await montar(tester);

    expect(find.bySemanticsLabel('Carregando mensagens'), findsOneWidget);
  });

  testWidgets('no tema escuro usa a cor de borda do tema escuro', (
    tester,
  ) async {
    await montar(tester, tema: AppTheme.dark);

    for (final bolha in bolhas(tester)) {
      final decoracao = bolha.decoration! as BoxDecoration;
      expect(decoracao.color, AppColors.dark.border);
    }
  });
}