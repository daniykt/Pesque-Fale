import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/assistente/presentation/widgets/compactar_ajuda_ao_rolar.dart';

void main() {
  const listaVertical = ValueKey('lista-vertical');
  const listaHorizontal = ValueKey('lista-horizontal');
  const estado = ValueKey('estado');

  Widget app({int abaAtual = 0}) {
    return MaterialApp(
      home: CompactarAjudaAoRolar(
        abaAtual: abaAtual,
        builder: (context, compacto) => Scaffold(
          body: Column(
            children: [
              SizedBox(
                height: 120,
                child: ListView(
                  key: listaHorizontal,
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < 30; i++)
                      SizedBox(width: 120, child: Text('Card $i')),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  key: listaVertical,
                  children: [
                    for (var i = 0; i < 60; i++)
                      SizedBox(height: 80, child: Text('Item $i')),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: Text(
            compacto ? 'compacto' : 'expandido',
            key: estado,
          ),
        ),
      ),
    );
  }

  String estadoAtual(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(estado)).data!;

  testWidgets('começa expandido', (tester) async {
    await tester.pumpWidget(app());

    expect(estadoAtual(tester), 'expandido');
  });

  testWidgets('rolar para baixo compacta e rolar para cima expande', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    await tester.drag(find.byKey(listaVertical), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(estadoAtual(tester), 'compacto');

    await tester.drag(find.byKey(listaVertical), const Offset(0, 150));
    await tester.pumpAndSettle();
    expect(estadoAtual(tester), 'expandido');
  });

  testWidgets('rolagem horizontal não muda o botão', (tester) async {
    await tester.pumpWidget(app());

    await tester.drag(find.byKey(listaHorizontal), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(estadoAtual(tester), 'expandido');

    await tester.drag(find.byKey(listaVertical), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(estadoAtual(tester), 'compacto');

    await tester.drag(find.byKey(listaHorizontal), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(estadoAtual(tester), 'compacto');
  });

  testWidgets('trocar de aba volta para expandido', (tester) async {
    await tester.pumpWidget(app());

    await tester.drag(find.byKey(listaVertical), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(estadoAtual(tester), 'compacto');

    await tester.pumpWidget(app(abaAtual: 1));
    expect(estadoAtual(tester), 'expandido');
  });
}
