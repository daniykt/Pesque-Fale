import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/core/router/main_shell.dart';
import 'package:pesque_fale_app/features/assistente/domain/mensagem_assistente.dart';
import 'package:pesque_fale_app/features/assistente/presentation/navegacao_assistente.dart';

void main() {
  testWidgets('pesquisa de locais volta para a home e seleciona a aba', (
    tester,
  ) async {
    int? abaSelecionada;

    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: Text('HOME')),
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => abrirAcaoDoAssistente(
                context,
                const AcaoAssistente(
                  tipo: TipoAcaoAssistente.abrirTela,
                  rotulo: 'Pesquisar',
                  tela: 'pesquisa_locais',
                ),
                onSelecionarAba: (i) => abaSelecionada = i,
              ),
              child: const Text('ASSISTENTE'),
            ),
          ),
        ),
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/assistente');
    await tester.pumpAndSettle();
    await tester.tap(find.text('ASSISTENTE'));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(abaSelecionada, MainShell.pesquisaIndex);
  });

  test('todas as telas conhecidas têm rota', () {
    expect(rotasDasTelasDoAssistente.keys, containsAll([
      'nova_publicacao',
      'editar_perfil',
      'configuracoes',
      'chat',
      'sobre',
    ]));
  });
}