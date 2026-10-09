import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pesque_fale_app/features/perfil/presentation/widgets/acoes_header_perfil.dart';

void main() {
  Future<void> montar(
    WidgetTester tester, {
    required VoidCallback onEditar,
    required VoidCallback onConfiguracoes,
    required VoidCallback onSobre,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              AcoesHeaderPerfil(
                onEditar: onEditar,
                onConfiguracoes: onConfiguracoes,
                onSobre: onSobre,
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('renderiza os tres botoes com os tooltips corretos', (
    tester,
  ) async {
    await montar(
      tester,
      onEditar: () {},
      onConfiguracoes: () {},
      onSobre: () {},
    );

    expect(find.byTooltip('Editar perfil'), findsOneWidget);
    expect(find.byTooltip('Configurações'), findsOneWidget);
    expect(find.byTooltip('Sobre Nós'), findsOneWidget);

    // Garante que ninguem reintroduziu o antigo menu agregador.
    expect(find.byTooltip('Mais opções'), findsNothing);
    expect(find.byIcon(Icons.more_horiz), findsNothing);
  });

  testWidgets('tap em Editar perfil dispara onEditar', (tester) async {
    var editouCount = 0;
    await montar(
      tester,
      onEditar: () => editouCount++,
      onConfiguracoes: () {},
      onSobre: () {},
    );

    await tester.tap(find.byTooltip('Editar perfil'));
    expect(editouCount, 1);
  });

  testWidgets('tap em Configurações dispara onConfiguracoes', (tester) async {
    var configCount = 0;
    await montar(
      tester,
      onEditar: () {},
      onConfiguracoes: () => configCount++,
      onSobre: () {},
    );

    await tester.tap(find.byTooltip('Configurações'));
    expect(configCount, 1);
  });

  testWidgets('tap em Sobre Nós dispara onSobre', (tester) async {
    var sobreCount = 0;
    await montar(
      tester,
      onEditar: () {},
      onConfiguracoes: () {},
      onSobre: () => sobreCount++,
    );

    await tester.tap(find.byTooltip('Sobre Nós'));
    expect(sobreCount, 1);
  });
}
