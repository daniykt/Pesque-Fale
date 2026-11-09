import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/shared/widgets/app_bottom_nav.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montarWidget(
    WidgetTester tester, {
    int currentIndex = 0,
    int? highlightedIndex,
    int notifCount = 0,
    int chatCount = 0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(
            currentIndex: currentIndex,
            onDestinationSelected: (_) {},
            highlightedIndex: highlightedIndex,
            notifCount: notifCount,
            chatCount: chatCount,
          ),
        ),
      ),
    );
  }

  testWidgets('renderiza os 5 destinos padrao', (tester) async {
    await montarWidget(tester);

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Pesquisa'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Alertas'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('sem highlightedIndex nenhum item tem borda de destaque', (
    tester,
  ) async {
    await montarWidget(tester);

    final containers = tester.widgetList<Container>(find.byType(Container));
    final algumComBorda = containers.any(
      (c) => c.decoration is BoxDecoration && (c.decoration! as BoxDecoration).border != null,
    );
    expect(algumComBorda, isFalse);
  });

  testWidgets('com highlightedIndex o item correspondente recebe borda', (
    tester,
  ) async {
    await montarWidget(tester, highlightedIndex: 2);

    final containers = tester.widgetList<Container>(find.byType(Container));
    final algumComBorda = containers.any(
      (c) => c.decoration is BoxDecoration && (c.decoration! as BoxDecoration).border != null,
    );
    expect(algumComBorda, isTrue);
  });

  testWidgets('onDestinationSelected e chamado ao tocar em um item', (
    tester,
  ) async {
    int? selecionado;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(
            currentIndex: 0,
            onDestinationSelected: (i) => selecionado = i,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pesquisa'));
    expect(selecionado, 1);
  });

  testWidgets('sem chatCount o icone de Chat nao mostra badge', (tester) async {
    await montarWidget(tester);

    // Badge só aparece com isLabelVisible: true, que acontece com chatCount > 0.
    // Com chatCount default 0, nenhum badge do Chat deve aparecer.
    expect(find.text('0'), findsNothing);
  });

  testWidgets('com chatCount > 0 o icone de Chat mostra o numero', (tester) async {
    await montarWidget(tester, chatCount: 5);

    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('com chatCount acima de 99 mostra 99+', (tester) async {
    await montarWidget(tester, chatCount: 150);

    expect(find.text('99+'), findsOneWidget);
  });
}
