import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_exceptions.dart';
import 'package:pesque_fale_app/features/feed/domain/evento.dart';
import 'package:pesque_fale_app/features/novo_evento/domain/data_hora_por_extenso.dart';
import 'package:pesque_fale_app/features/novo_evento/presentation/novo_evento_page.dart';
import 'package:pesque_fale_app/features/novo_evento/providers/novo_evento_provider.dart';

import '../fakes.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  final amanha = DateTime.now().add(const Duration(days: 1));
  final inicio = DateTime(amanha.year, amanha.month, amanha.day, 7);

  for (final (nomeTema, criarTema) in [
    ('claro', () => AppTheme.light),
    ('escuro', () => AppTheme.dark),
  ]) {
    group('tema $nomeTema', () {
      late FakeEventosRepository repo;
      late FakeUploadRepository upload;
      late NovoEventoProvider provider;
      Evento? resultado;

      setUp(() {
        repo = FakeEventosRepository();
        upload = FakeUploadRepository();
        resultado = null;
      });

      Future<void> abrir(
        WidgetTester tester, {
        Evento? evento,
        void Function(NovoEventoProvider)? preparar,
      }) async {
        provider = NovoEventoProvider(
          repository: repo,
          uploadRepository: upload,
          evento: evento,
        );
        preparar?.call(provider);
        await tester.pumpWidget(
          MaterialApp(
            theme: criarTema(),
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [Locale('pt', 'BR')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      resultado = await Navigator.of(context).push<Evento>(
                        MaterialPageRoute(
                          builder: (_) =>
                              ChangeNotifierProvider<NovoEventoProvider>.value(
                                value: provider,
                                child: const NovoEventoPage(),
                              ),
                        ),
                      );
                    },
                    child: const Text('abrir'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('abrir'));
        await tester.pumpAndSettle();
      }

      Future<void> tocarEmCriar(WidgetTester tester, String rotulo) async {
        final botao = find.widgetWithText(FilledButton, rotulo);
        await tester.ensureVisible(botao);
        await tester.pumpAndSettle();
        await tester.tap(botao);
        await tester.pump();
      }

      testWidgets('mostra os campos do novo evento', (tester) async {
        await abrir(tester);

        expect(find.text('Novo evento'), findsOneWidget);
        expect(find.text('Título *'), findsOneWidget);
        expect(find.text('Início *'), findsOneWidget);
        expect(find.text('Fim (opcional)'), findsOneWidget);
        expect(find.text('Local (opcional)'), findsOneWidget);
        expect(find.text('Escolher um ponto da lista'), findsOneWidget);
        expect(find.text('Descrição'), findsOneWidget);
        expect(find.text('Foto (opcional)'), findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, 'Criar evento'),
          findsOneWidget,
        );
      });

      testWidgets('enviar vazio mostra os erros embaixo dos campos', (
        tester,
      ) async {
        await abrir(tester);

        await tocarEmCriar(tester, 'Criar evento');
        await tester.pumpAndSettle();

        expect(
          find.text('O título precisa ter entre 2 e 200 caracteres.'),
          findsOneWidget,
        );
        expect(find.text('Escolha a data e a hora de início.'), findsOneWidget);
        expect(repo.criados, isEmpty);
      });

      testWidgets('erro 400 da API aparece embaixo do campo', (tester) async {
        repo.erro = EventoValidacaoException({
          'dataFim':
              'A data de fim deve ser igual ou posterior à data de início.',
          'titulo': 'Título deve ter entre 2 e 200 caracteres.',
        });
        await abrir(
          tester,
          preparar: (p) => p
            ..setTitulo('Torneio')
            ..setDataInicio(inicio),
        );

        await tocarEmCriar(tester, 'Criar evento');
        await tester.pumpAndSettle();

        expect(
          find.text(
            'A data de fim deve ser igual ou posterior à data de início.',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Título deve ter entre 2 e 200 caracteres.'),
          findsOneWidget,
        );
        expect(find.text('Confira os campos destacados.'), findsOneWidget);
      });

      testWidgets('enquanto envia, mostra "Salvando..." e ignora outro toque', (
        tester,
      ) async {
        final segurar = Completer<void>();
        repo.segurar = segurar;
        await abrir(
          tester,
          preparar: (p) => p
            ..setTitulo('Torneio')
            ..setDataInicio(inicio),
        );

        await tocarEmCriar(tester, 'Criar evento');
        expect(find.text('Salvando...'), findsOneWidget);
        final botao = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(botao.onPressed, isNull);
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        segurar.complete();
        await tester.pumpAndSettle();
        expect(repo.criados, hasLength(1));
      });

      testWidgets('sucesso volta com o evento e mostra a mensagem', (
        tester,
      ) async {
        await abrir(
          tester,
          preparar: (p) => p
            ..setTitulo('Torneio do Lago')
            ..setDataInicio(inicio),
        );

        await tocarEmCriar(tester, 'Criar evento');
        await tester.pumpAndSettle();

        expect(find.byType(NovoEventoPage), findsNothing);
        expect(resultado?.titulo, 'Torneio do Lago');
        expect(find.text('Evento criado!'), findsOneWidget);
      });

      testWidgets('voltar sem mexer em nada não pede confirmação', (
        tester,
      ) async {
        await abrir(tester);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.byType(NovoEventoPage), findsNothing);
      });

      testWidgets('voltar com dados preenchidos confirma numa bottom sheet', (
        tester,
      ) async {
        await abrir(tester);
        await tester.enterText(find.byType(TextFormField), 'Torneio');
        await tester.pump();

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text('Descartar o evento?'), findsOneWidget);

        await tester.tap(find.text('Continuar editando'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byType(NovoEventoPage), findsOneWidget);
        expect(find.text('Torneio'), findsOneWidget);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Descartar'));
        await tester.pumpAndSettle();
        expect(find.byType(NovoEventoPage), findsNothing);
        expect(repo.criados, isEmpty);
      });

      testWidgets('mostra a data escolhida por extenso', (tester) async {
        await abrir(tester, preparar: (p) => p.setDataInicio(inicio));

        expect(find.text(dataHoraPorExtenso(inicio)), findsOneWidget);
        expect(find.textContaining(', às 07:00'), findsOneWidget);
      });

      testWidgets('os seletores de data e hora abrem em pt-BR', (tester) async {
        await abrir(tester);

        await tester.tap(find.byKey(const ValueKey('campo-inicio')));
        await tester.pumpAndSettle();
        expect(find.text('Quando começa?'), findsOneWidget);
        expect(find.text('Cancelar'), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text('Que horas?'), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(provider.dataInicio, inicio);
        expect(find.text(dataHoraPorExtenso(inicio)), findsOneWidget);
      });

      testWidgets('edição: título, campos preenchidos e botão de salvar', (
        tester,
      ) async {
        final evento = Evento(
          id: 'ev-1',
          titulo: 'Torneio antigo',
          organizadorId: 'mock-id',
          organizadorNome: 'Ana',
          dataInicio: inicio,
          localTexto: 'Rio Mogi',
          criadoEm: DateTime(2026, 11, 1),
        );
        await abrir(tester, evento: evento);

        expect(find.text('Editar evento'), findsOneWidget);
        expect(find.text('Torneio antigo'), findsOneWidget);
        expect(find.text('Rio Mogi'), findsOneWidget);
        expect(find.text(dataHoraPorExtenso(inicio)), findsOneWidget);

        await tocarEmCriar(tester, 'Salvar alterações');
        await tester.pumpAndSettle();

        expect(repo.editados.single.$1, 'ev-1');
        expect(find.text('Evento atualizado!'), findsOneWidget);
      });

      testWidgets('cabe em 360dp com fonte 1.3, inclusive com erros', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await abrir(
          tester,
          preparar: (p) => p
            ..setDataInicio(inicio)
            ..setDataFim(inicio.add(const Duration(hours: 5)))
            ..setPonto(
              const PontoDoEvento(
                id: 'p-1',
                nome: 'Represa de Ibitinga, área de pesca esportiva',
                regiao: 'Ibitinga-SP',
              ),
            ),
        );
        await tocarEmCriar(tester, 'Criar evento');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Trocar ponto'), findsOneWidget);
        final tamanho = tester.getSize(find.byType(FilledButton));
        expect(tamanho.height, greaterThanOrEqualTo(48));
        for (final rotulo in ['Trocar ponto', 'Escrever outro local']) {
          final alvo = tester.getSize(find.widgetWithText(TextButton, rotulo));
          expect(alvo.height, greaterThanOrEqualTo(48), reason: rotulo);
        }
      });
    });
  }
}
