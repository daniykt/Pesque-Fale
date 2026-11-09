import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/shared/widgets/estado_centralizado_rolavel.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montarWidget(
    WidgetTester tester, {
    required double alturaArea,
    required double alturaFilho,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 300,
              height: alturaArea,
              child: EstadoCentralizadoRolavel(
                child: SizedBox(
                  key: const Key('filho'),
                  width: 100,
                  height: alturaFilho,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('filho maior que a area nao estoura e fica rolavel', (
    tester,
  ) async {
    await montarWidget(tester, alturaArea: 200, alturaFilho: 400);

    expect(tester.takeException(), isNull);

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('filho pequeno numa area grande continua centralizado', (
    tester,
  ) async {
    await montarWidget(tester, alturaArea: 500, alturaFilho: 50);

    expect(tester.takeException(), isNull);

    final area = tester.getRect(find.byType(EstadoCentralizadoRolavel));
    final filho = tester.getRect(find.byKey(const Key('filho')));
    expect(filho.center.dy, closeTo(area.center.dy, 0.5));
    expect(filho.center.dx, closeTo(area.center.dx, 0.5));

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, 0);
  });
}
