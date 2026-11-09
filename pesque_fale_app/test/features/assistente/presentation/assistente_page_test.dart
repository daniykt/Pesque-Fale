import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/assistente/data/assistente_exceptions.dart';
import 'package:pesque_fale_app/features/assistente/data/assistente_repository.dart';
import 'package:pesque_fale_app/features/assistente/domain/mensagem_assistente.dart';
import 'package:pesque_fale_app/features/assistente/presentation/assistente_page.dart';
import 'package:pesque_fale_app/features/assistente/providers/assistente_provider.dart';
import 'package:pesque_fale_app/features/assistente/providers/voz_provider.dart';

import '../support/fake_servico_voz.dart';

class _FakeAssistenteRepository implements AssistenteRepository {
  final List<String> perguntas = [];
  Completer<RespostaAssistente>? pendente;
  Object? erro;
  RespostaAssistente resposta = const RespostaAssistente(
    resposta: 'Toque no botão abaixo.',
    acoes: [
      AcaoAssistente(
        tipo: TipoAcaoAssistente.abrirLocal,
        rotulo: 'Ver Lago Azul',
        pontoId: 'ponto-1',
      ),
      AcaoAssistente(
        tipo: TipoAcaoAssistente.abrirTela,
        rotulo: 'Abrir tela de publicar',
        tela: 'nova_publicacao',
      ),
    ],
  );

  @override
  Future<RespostaAssistente> perguntar({
    required String mensagem,
    required List<MensagemAssistente> historico,
    String? tela,
  }) {
    perguntas.add(mensagem);
    if (pendente != null) return pendente!.future;
    if (erro != null) return Future.error(erro!);
    return Future.value(resposta);
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late _FakeAssistenteRepository repo;
  late FakeServicoVoz voz;

  setUp(() {
    repo = _FakeAssistenteRepository();
    voz = FakeServicoVoz();
  });

  Future<void> montar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ChangeNotifierProvider(
          create: (_) => AssistenteProvider(repository: repo),
          child: AssistentePage(servicoVoz: voz),
        ),
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Text('ROTA ${settings.name} ${settings.arguments ?? ''}'),
          ),
        ),
      ),
    );
  }

  testWidgets('abre com o aviso de assistente virtual e as sugestões', (
    tester,
  ) async {
    await montar(tester);

    expect(find.textContaining('é um assistente virtual e pode errar'), findsOneWidget);
    for (final sugestao in AssistenteProvider.sugestoes) {
      expect(find.text(sugestao), findsOneWidget);
    }
  });

  testWidgets('tocar numa sugestão envia a pergunta e mostra a resposta', (
    tester,
  ) async {
    await montar(tester);

    await tester.tap(find.text(AssistenteProvider.sugestoes.first));
    await tester.pumpAndSettle();

    expect(repo.perguntas, [AssistenteProvider.sugestoes.first]);
    expect(find.text(AssistenteProvider.sugestoes.first), findsOneWidget);
    expect(find.text('Toque no botão abaixo.'), findsOneWidget);
    expect(find.text('Ver Lago Azul'), findsOneWidget);
    expect(find.text('Abrir tela de publicar'), findsOneWidget);
  });

  testWidgets('envia a pergunta digitada no campo', (tester) async {
    await montar(tester);

    await tester.enterText(find.byType(TextField), 'Como sigo alguém?');
    await tester.tap(find.byTooltip('Enviar pergunta'));
    await tester.pumpAndSettle();

    expect(repo.perguntas, ['Como sigo alguém?']);
    expect(find.text('Como sigo alguém?'), findsOneWidget);
  });

  testWidgets('mostra que o Pirá está pensando e depois o aviso de demora', (tester) async {
    repo.pendente = Completer();
    await montar(tester);

    await tester.tap(find.text(AssistenteProvider.sugestoes.first));
    await tester.pump();
    expect(find.text('O Pirá está pensando...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    expect(find.textContaining('Acordando o Pirá'), findsOneWidget);

    repo.pendente!.complete(const RespostaAssistente(resposta: 'Pronto.'));
    await tester.pumpAndSettle();
    expect(find.text('Pronto.'), findsOneWidget);
    expect(find.textContaining('Acordando o Pirá'), findsNothing);
  });

  testWidgets('botão de local abre o detalhe do ponto', (tester) async {
    await montar(tester);
    await tester.tap(find.text(AssistenteProvider.sugestoes.first));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver Lago Azul'));
    await tester.pumpAndSettle();

    expect(find.text('ROTA /pontos ponto-1'), findsOneWidget);
  });

  testWidgets('botão de tela abre a tela certa', (tester) async {
    await montar(tester);
    await tester.tap(find.text(AssistenteProvider.sugestoes.first));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir tela de publicar'));
    await tester.pumpAndSettle();

    expect(find.text('ROTA /publicacao/nova '), findsOneWidget);
  });

  testWidgets('erro mostra a mensagem amigável e "Tentar de novo"', (
    tester,
  ) async {
    repo.erro = const AssistenteIndisponivelException();
    await montar(tester);

    await tester.tap(find.text(AssistenteProvider.sugestoes.first));
    await tester.pumpAndSettle();

    expect(
      find.text(const AssistenteIndisponivelException().message),
      findsOneWidget,
    );

    repo.erro = null;
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(repo.perguntas, hasLength(2));
    expect(find.text('Toque no botão abaixo.'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsNothing);
  });

  testWidgets('o microfone escreve a pergunta falada no campo', (tester) async {
    await montar(tester);

    await tester.tap(find.byTooltip('Falar a pergunta'));
    await tester.pump();
    expect(find.byTooltip('Parar de ouvir'), findsOneWidget);
    expect(find.text('Pode falar, estou ouvindo...'), findsOneWidget);

    voz.onTexto!('Como publico');
    voz.onTexto!('Como publico uma pescaria?');
    voz.terminarEscuta();
    await tester.pump();

    final campo = tester.widget<TextField>(find.byType(TextField));
    expect(campo.controller!.text, 'Como publico uma pescaria?');
    expect(find.byTooltip('Falar a pergunta'), findsOneWidget);

    await tester.tap(find.byTooltip('Enviar pergunta'));
    await tester.pumpAndSettle();

    expect(repo.perguntas, ['Como publico uma pescaria?']);
  });

  testWidgets('avisa quando o microfone não pode ser usado', (tester) async {
    voz.microfoneLiberado = false;
    await montar(tester);

    await tester.tap(find.byTooltip('Falar a pergunta'));
    await tester.pump();

    expect(find.text(VozProvider.avisoMicrofone), findsOneWidget);
    expect(find.byTooltip('Falar a pergunta'), findsOneWidget);
  });

  testWidgets('"Ouvir" lê a resposta do Pirá e vira "Parar"', (tester) async {
    await montar(tester);
    await tester.tap(find.text(AssistenteProvider.sugestoes.first));
    await tester.pumpAndSettle();

    expect(find.text('Ouvir'), findsOneWidget);

    await tester.tap(find.text('Ouvir'));
    await tester.pump();

    expect(voz.lidos, ['Toque no botão abaixo.']);
    expect(find.text('Parar'), findsOneWidget);

    voz.terminarLeitura();
    await tester.pump();

    expect(find.text('Ouvir'), findsOneWidget);
    expect(find.text('Parar'), findsNothing);
  });

  testWidgets('"Parar" interrompe a leitura', (tester) async {
    await montar(tester);
    await tester.tap(find.text(AssistenteProvider.sugestoes.first));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ouvir'));
    await tester.pump();
    await tester.tap(find.text('Parar'));
    await tester.pump();

    expect(voz.paradasLeitura, greaterThan(0));
    expect(find.text('Ouvir'), findsOneWidget);
  });
}