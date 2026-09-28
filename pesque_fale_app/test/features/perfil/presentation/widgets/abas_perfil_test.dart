import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/perfil/presentation/widgets/abas_perfil.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montarWidget(WidgetTester tester) async {
    // No PerfilPage as abas ficam dentro de uma lista rolável.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: AbasPerfil(publicacoes: [], isOwnProfile: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('TabBar e rolavel e alinhado ao inicio', (tester) async {
    await montarWidget(tester);

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.isScrollable, isTrue);
    expect(tabBar.tabAlignment, TabAlignment.start);
  });

  testWidgets('em 360dp com fonte 1.3 os 3 rotulos aparecem sem overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await montarWidget(tester);

    expect(tester.takeException(), isNull);
    for (final rotulo in ['Galeria', 'Equipamentos', 'Locais Salvos']) {
      expect(find.text(rotulo), findsOneWidget);
      // O Tab corta com fade em vez de lançar erro, então conferimos que o
      // texto foi desenhado na largura inteira.
      final paragrafo = tester.renderObject<RenderParagraph>(find.text(rotulo));
      expect(
        paragrafo.size.width,
        greaterThanOrEqualTo(
          paragrafo.getMaxIntrinsicWidth(double.infinity) - 0.5,
        ),
        reason: '"$rotulo" foi truncado',
      );
    }
  });
}
