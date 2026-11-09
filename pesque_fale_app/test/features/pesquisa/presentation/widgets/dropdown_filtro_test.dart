import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/tipo_ponto.dart';
import 'package:pesque_fale_app/features/pesquisa/presentation/widgets/dropdown_filtro.dart';

class _Host extends StatefulWidget {
  const _Host({required this.aoMudar});

  final ValueChanged<TipoPonto?> aoMudar;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  TipoPonto? valor;

  void definir(TipoPonto? novo) => setState(() => valor = novo);

  @override
  Widget build(BuildContext context) {
    return DropdownFiltro<TipoPonto?>(
      titulo: 'Tipo',
      valor: valor,
      itens: const [null, ...TipoPonto.values],
      labelDe: (t) => t?.label ?? 'Todos',
      onChanged: (novo) {
        widget.aoMudar(novo);
        definir(novo);
      },
    );
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  final recebidos = <TipoPonto?>[];

  Future<_HostState> montar(WidgetTester tester) async {
    recebidos.clear();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: _Host(aoMudar: recebidos.add)),
      ),
    );
    return tester.state<_HostState>(find.byType(_Host));
  }

  Future<void> escolher(WidgetTester tester, String atual, String novo) async {
    await tester.tap(find.text(atual));
    await tester.pumpAndSettle();
    await tester.tap(find.text(novo).last);
    await tester.pumpAndSettle();
  }

  testWidgets('escolher Todos repassa null', (tester) async {
    await montar(tester);

    await escolher(tester, 'Todos', 'Rio');
    await escolher(tester, 'Rio', 'Todos');

    expect(recebidos, [TipoPonto.rio, null]);
  });

  testWidgets('acompanha o valor quando ele muda por fora', (tester) async {
    final host = await montar(tester);

    host.definir(TipoPonto.lago);
    await tester.pump();
    expect(find.text('Lago'), findsOneWidget);

    host.definir(null);
    await tester.pump();
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Lago'), findsNothing);
  });
}
