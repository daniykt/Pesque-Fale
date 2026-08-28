import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/configuracoes/presentation/widgets/configuracoes_secao.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montarWidget(WidgetTester tester, Widget secao) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: Scaffold(body: secao)),
    );
  }

  testWidgets('renderiza titulo em uppercase', (tester) async {
    await montarWidget(
      tester,
      const ConfiguracoesSecao(
        titulo: 'Aparência',
        itens: [ListTile(title: Text('Item 1'))],
      ),
    );

    expect(find.text('APARÊNCIA'), findsOneWidget);
    expect(find.text('Aparência'), findsNothing);
  });

  testWidgets('renderiza N itens com N-1 dividers entre eles', (
    tester,
  ) async {
    await montarWidget(
      tester,
      const ConfiguracoesSecao(
        titulo: 'Conta',
        itens: [
          ListTile(title: Text('Item 1')),
          ListTile(title: Text('Item 2')),
          ListTile(title: Text('Item 3')),
        ],
      ),
    );

    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 3'), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('renderiza apenas 1 item sem divider', (tester) async {
    await montarWidget(
      tester,
      const ConfiguracoesSecao(
        titulo: 'Sobre',
        itens: [ListTile(title: Text('Item unico'))],
      ),
    );

    expect(find.text('Item unico'), findsOneWidget);
    expect(find.byType(Divider), findsNothing);
  });
}
