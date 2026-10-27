import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/nova_publicacao/presentation/widgets/selecao_ponto_bottom_sheet.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_exceptions.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_repository.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/filtros_locais.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/ponto.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/tipo_ponto.dart';

/// Cada chamada a [buscar] consome a próxima resposta da fila; uma resposta
/// que é [PontosException] é lançada em vez de retornada.
class _FakePontosRepository implements PontosRepository {
  _FakePontosRepository(this._respostas);

  final List<Object> _respostas;
  int chamadas = 0;

  @override
  Future<List<Ponto>> buscar({
    required FiltrosLocais filtros,
    double? lat,
    double? lng,
    bool incluirDistancia = false,
    String? ordem,
  }) async {
    final resposta = _respostas[chamadas++];
    if (resposta is Completer<List<Ponto>>) return resposta.future;
    if (resposta is PontosException) throw resposta;
    return resposta as List<Ponto>;
  }

  @override
  Future<Ponto> buscarPorId(String id) async => throw UnimplementedError();
}

Ponto _ponto(String id, String nome, TipoPonto tipo) => Ponto(
  id: id,
  nome: nome,
  latitude: 0,
  longitude: 0,
  cidade: 'Matão',
  estado: 'SP',
  tipo: tipo,
  criadoPor: 'admin',
);

final _pontos = [
  _ponto('1', 'Rio Jacaré', TipoPonto.rio),
  _ponto('2', 'Represa do Lobo', TipoPonto.represa),
  _ponto('3', 'Pesqueiro São João', TipoPonto.pesqueiro),
];

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Ponto? resultado;
  var fechou = false;

  Future<void> abrirSheet(
    WidgetTester tester,
    PontosRepository repository,
  ) async {
    resultado = null;
    fechou = false;
    await tester.pumpWidget(
      Provider<PontosRepository>.value(
        value: repository,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  resultado = await SelecaoPontoBottomSheet.show(context);
                  fechou = true;
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('renderiza loading inicial', (tester) async {
    final completer = Completer<List<Ponto>>();
    await abrirSheet(tester, _FakePontosRepository([completer]));

    expect(find.text('Escolher local da pescaria'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_pontos);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renderiza lista de pontos e rodapé de contato', (tester) async {
    await abrirSheet(tester, _FakePontosRepository([_pontos]));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(3));
    expect(find.text('Rio Jacaré'), findsOneWidget);
    expect(find.text('Represa · Matão-SP'), findsOneWidget);
    expect(find.text('Pesqueiro · Matão-SP'), findsOneWidget);
    expect(
      find.text(
        'Não encontrou o seu local? Fale conosco: contato@pesquefale.app',
      ),
      findsOneWidget,
    );
  });

  testWidgets('busca filtra por nome sem diferenciar maiúsculas', (
    tester,
  ) async {
    await abrirSheet(tester, _FakePontosRepository([_pontos]));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'REPRESA');
    await tester.pump();

    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('Represa do Lobo'), findsOneWidget);
    expect(find.text('Rio Jacaré'), findsNothing);

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pump();

    expect(find.byType(ListTile), findsNothing);
    expect(find.text('Nenhum ponto encontrado para "xyz"'), findsOneWidget);
  });

  testWidgets('mostra empty state quando o repositório não tem pontos', (
    tester,
  ) async {
    await abrirSheet(tester, _FakePontosRepository([<Ponto>[]]));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Nenhum ponto cadastrado ainda. Fale com a equipe pra sugerir.',
      ),
      findsOneWidget,
    );
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('tap em um ponto fecha o sheet retornando o ponto', (
    tester,
  ) async {
    await abrirSheet(tester, _FakePontosRepository([_pontos]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Represa do Lobo'));
    await tester.pumpAndSettle();

    expect(fechou, isTrue);
    expect(resultado?.id, '2');
    expect(find.text('Escolher local da pescaria'), findsNothing);
  });

  testWidgets('erro mostra "Tentar novamente" que refaz o fetch', (
    tester,
  ) async {
    final repository = _FakePontosRepository([
      const NetworkException(),
      _pontos,
    ]);
    await abrirSheet(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('Sem conexão com o servidor.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(repository.chamadas, 1);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(repository.chamadas, 2);
    expect(find.text('Tentar novamente'), findsNothing);
    expect(find.byType(ListTile), findsNWidgets(3));
  });
}
