import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/feed/presentation/widgets/novas_publicacoes_button.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montar(
    WidgetTester tester, {
    required int quantidade,
    VoidCallback? onTap,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: NovasPublicacoesButton(
              quantidade: quantidade,
              onTap: onTap ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('quantidade 1 usa o singular', (tester) async {
    await montar(tester, quantidade: 1);

    expect(find.text('1 nova publicação'), findsOneWidget);
  });

  testWidgets('quantidade maior que 1 usa o plural', (tester) async {
    await montar(tester, quantidade: 5);

    expect(find.text('5 novas publicações'), findsOneWidget);
  });

  testWidgets('tap chama onTap', (tester) async {
    var toques = 0;
    await montar(tester, quantidade: 2, onTap: () => toques++);

    await tester.tap(find.byType(NovasPublicacoesButton));

    expect(toques, 1);
  });
}
