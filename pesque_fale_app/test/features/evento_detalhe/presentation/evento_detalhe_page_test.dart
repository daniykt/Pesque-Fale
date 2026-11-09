import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/evento_detalhe/presentation/evento_detalhe_page.dart';
import 'package:pesque_fale_app/features/evento_detalhe/providers/evento_detalhe_provider.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_exceptions.dart';
import 'package:pesque_fale_app/features/feed/domain/evento.dart';
import 'package:pesque_fale_app/features/feed/presentation/widgets/evento_card.dart';
import 'package:pesque_fale_app/features/novo_evento/domain/data_hora_por_extenso.dart';
import 'package:pesque_fale_app/shared/widgets/imagem_placeholder.dart';

import '../fakes.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  final agora = DateTime(2026, 11, 7, 10);
  DateTime relogio() => agora;

  for (final (nomeTema, criarTema) in [
    ('claro', () => AppTheme.light),
    ('escuro', () => AppTheme.dark),
  ]) {
    group('tema $nomeTema', () {
      late FakeEventosDetalheRepository repo;
      late List<RouteSettings> rotasEditar;
      late List<RouteSettings> outrasRotas;
      Evento? editadoDevolvido;
      Object? resultadoDetalhe;

      setUp(() {
        repo = FakeEventosDetalheRepository();
        rotasEditar = [];
        outrasRotas = [];
        editadoDevolvido = null;
        resultadoDetalhe = null;
      });

      Future<void> abrir(
        WidgetTester tester, {
        required Evento evento,
        String? usuarioId,
        bool comEventoInicial = true,
      }) async {
        repo.atual ??= evento;
        final auth = AuthProvider(
          repository: FakeAuthRepository(usuarioId ?? 'ninguem'),
        );
        if (usuarioId != null) {
          await auth.login(email: 'teste@exemplo.com', senha: '123456');
        }
        await tester.pumpWidget(
          ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: MaterialApp(
              theme: criarTema(),
              locale: const Locale('pt', 'BR'),
              supportedLocales: const [Locale('pt', 'BR')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              onGenerateRoute: (settings) {
                if (settings.name == '/evento/editar') {
                  rotasEditar.add(settings);
                  return MaterialPageRoute<Evento>(
                    builder: (context) => Scaffold(
                      body: TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(editadoDevolvido),
                        child: const Text('salvar edição'),
                      ),
                    ),
                  );
                }
                if (settings.name == '/pontos' || settings.name == '/perfil') {
                  outrasRotas.add(settings);
                  return MaterialPageRoute<void>(
                    builder: (_) =>
                        Scaffold(body: Text('rota ${settings.name}')),
                  );
                }
                return null;
              },
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () async {
                        resultadoDetalhe = await Navigator.of(context).push(
                          MaterialPageRoute<Object>(
                            builder: (_) =>
                                ChangeNotifierProvider<EventoDetalheProvider>(
                                  create: (_) => EventoDetalheProvider(
                                    repository: repo,
                                    eventoInicial: comEventoInicial
                                        ? evento
                                        : null,
                                    eventoId: evento.id,
                                  ),
                                  child: EventoDetalhePage(agora: relogio),
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
          ),
        );
        await tester.tap(find.text('abrir'));
        await tester.pumpAndSettle();
      }

      Future<void> tocar(WidgetTester tester, Finder alvo) async {
        await tester.ensureVisible(alvo);
        await tester.pumpAndSettle();
        await tester.tap(alvo);
        await tester.pumpAndSettle();
      }

      testWidgets('mostra os dados do evento', (tester) async {
        final evento = eventoDeTeste(fim: DateTime(2026, 11, 20, 13));
        await abrir(tester, evento: evento);

        expect(find.text('Torneio do Lago Azul'), findsOneWidget);
        expect(
          find.text(dataHoraPorExtenso(evento.dataInicio)),
          findsOneWidget,
        );
        expect(find.text(dataHoraPorExtenso(evento.dataFim!)), findsOneWidget);
        expect(find.text('Lago Azul, Matão-SP'), findsOneWidget);
        expect(find.text('Ana Souza'), findsOneWidget);
        expect(find.text('@ana_pesca'), findsOneWidget);
        expect(
          find.text('Premiação para os três maiores peixes.'),
          findsOneWidget,
        );
        expect(find.byType(ImagemIndisponivel), findsOneWidget);
        expect(find.textContaining('em breve'), findsNothing);
      });

      testWidgets('sem local e sem descrição, não inventa', (tester) async {
        await abrir(
          tester,
          evento: eventoDeTeste(descricao: null, localTexto: null),
        );

        expect(find.text('Não informado'), findsOneWidget);
        expect(find.text('Sobre o evento'), findsNothing);
      });

      testWidgets('organizador vê editar e excluir', (tester) async {
        await abrir(tester, evento: eventoDeTeste(), usuarioId: 'organizador');

        expect(find.text('Organizado por você'), findsOneWidget);
        expect(find.text('Editar evento'), findsOneWidget);
        expect(find.text('Excluir evento'), findsOneWidget);
      });

      testWidgets('outro usuário não vê editar nem excluir', (tester) async {
        await abrir(tester, evento: eventoDeTeste(), usuarioId: 'outra-pessoa');

        expect(find.text('Organizado por'), findsOneWidget);
        expect(find.text('Editar evento'), findsNothing);
        expect(find.text('Excluir evento'), findsNothing);
      });

      testWidgets('sem login, não vê editar nem excluir', (tester) async {
        await abrir(tester, evento: eventoDeTeste());

        expect(find.text('Editar evento'), findsNothing);
        expect(find.text('Excluir evento'), findsNothing);
      });

      testWidgets('excluir pede confirmação numa bottom sheet e sai', (
        tester,
      ) async {
        await abrir(tester, evento: eventoDeTeste(), usuarioId: 'organizador');

        await tocar(tester, find.text('Excluir evento'));
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text('Excluir o evento?'), findsOneWidget);

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(repo.excluidos, isEmpty);
        expect(find.byType(EventoDetalhePage), findsOneWidget);

        await tocar(tester, find.text('Excluir evento'));
        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text('Excluir evento'),
          ),
        );
        await tester.pumpAndSettle();

        expect(repo.excluidos, ['ev-1']);
        expect(find.byType(EventoDetalhePage), findsNothing);
        expect(find.text('Evento excluído.'), findsOneWidget);
        expect(resultadoDetalhe, isTrue);
      });

      testWidgets('falha ao excluir mostra a mensagem e fica na tela', (
        tester,
      ) async {
        repo.erroExcluir = const EventosRedeException();
        await abrir(tester, evento: eventoDeTeste(), usuarioId: 'organizador');

        await tocar(tester, find.text('Excluir evento'));
        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text('Excluir evento'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EventoDetalhePage), findsOneWidget);
        expect(find.text('Sem conexão com o servidor.'), findsOneWidget);
      });

      testWidgets('editar abre a tela de edição e mostra o editado', (
        tester,
      ) async {
        final evento = eventoDeTeste();
        editadoDevolvido = eventoDeTeste(titulo: 'Torneio com novo nome');
        await abrir(tester, evento: evento, usuarioId: 'organizador');

        await tocar(tester, find.text('Editar evento'));
        expect(rotasEditar.single.arguments, same(evento));

        await tester.tap(find.text('salvar edição'));
        await tester.pumpAndSettle();

        expect(find.text('Torneio com novo nome'), findsOneWidget);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.byType(EventoDetalhePage), findsNothing);
        expect(resultadoDetalhe, isA<Evento>());
        expect((resultadoDetalhe as Evento).titulo, 'Torneio com novo nome');
      });

      testWidgets('voltar sem editar nem excluir não devolve nada', (
        tester,
      ) async {
        await abrir(tester, evento: eventoDeTeste(), usuarioId: 'organizador');

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.byType(EventoDetalhePage), findsNothing);
        expect(resultadoDetalhe, isNull);
      });

      testWidgets('evento que não existe mais mostra aviso e "Voltar"', (
        tester,
      ) async {
        repo.erroBuscar = const EventoNaoEncontradoException();
        await abrir(tester, evento: eventoDeTeste());

        expect(find.text('Este evento não existe mais.'), findsOneWidget);
        await tocar(tester, find.text('Voltar'));
        expect(find.byType(EventoDetalhePage), findsNothing);
      });

      testWidgets('erro de rede sem evento mostra "Tentar de novo"', (
        tester,
      ) async {
        repo.erroBuscar = const EventosRedeException();
        await abrir(tester, evento: eventoDeTeste(), comEventoInicial: false);

        expect(find.text('Sem conexão com o servidor.'), findsOneWidget);

        repo.erroBuscar = null;
        await tocar(tester, find.text('Tentar de novo'));

        expect(find.text('Torneio do Lago Azul'), findsOneWidget);
      });

      for (final (nome, inicio, termino, mostra) in [
        ('já começou e não terminou', -1, 1, true),
        ('começou agora, sem fim', 0, null, true),
        ('ainda vai começar', 2, 4, false),
        ('já terminou', -48, -24, false),
      ]) {
        testWidgets('selo "Acontecendo agora": $nome', (tester) async {
          await abrir(
            tester,
            evento: eventoDeTeste(
              inicio: agora.add(Duration(hours: inicio)),
              fim: termino == null ? null : agora.add(Duration(hours: termino)),
            ),
          );

          expect(
            find.text('Acontecendo agora'),
            mostra ? findsOneWidget : findsNothing,
          );
          expect(find.text('Já terminou'), findsNothing);
        });
      }

      testWidgets('local com ponto abre o ponto em /pontos', (tester) async {
        await abrir(tester, evento: eventoDeTeste(pontoId: 'ponto-9'));

        await tocar(tester, find.text('Lago Azul, Matão-SP'));

        expect(outrasRotas.single.name, '/pontos');
        expect(outrasRotas.single.arguments, 'ponto-9');
        expect(find.text('rota /pontos'), findsOneWidget);
      });

      testWidgets('local sem ponto não abre nada', (tester) async {
        await abrir(tester, evento: eventoDeTeste());

        await tocar(tester, find.text('Lago Azul, Matão-SP'));

        expect(outrasRotas, isEmpty);
        expect(find.byType(EventoDetalhePage), findsOneWidget);
      });

      testWidgets('tocar no organizador abre o perfil dele', (tester) async {
        await abrir(tester, evento: eventoDeTeste(), usuarioId: 'outra-pessoa');

        await tocar(tester, find.text('Ana Souza'));

        expect(outrasRotas.single.name, '/perfil');
        expect(outrasRotas.single.arguments, 'organizador');
      });

      testWidgets('cabe em 360dp com fonte 1.3, com botões de 48', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await abrir(
          tester,
          evento: eventoDeTeste(
            titulo: 'Grande torneio regional de pesca esportiva do interior',
            fim: DateTime(2026, 11, 22, 18),
            pontoId: 'ponto-9',
          ),
          usuarioId: 'organizador',
        );

        expect(tester.takeException(), isNull);
        for (final rotulo in ['Editar evento', 'Excluir evento']) {
          final botao = find.ancestor(
            of: find.text(rotulo),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          );
          expect(tester.getSize(botao).height, greaterThanOrEqualTo(48));
        }
        for (final texto in ['Lago Azul, Matão-SP', 'Ana Souza']) {
          final alvo = find.ancestor(
            of: find.text(texto),
            matching: find.byType(InkWell),
          );
          expect(
            tester.getSize(alvo.first).height,
            greaterThanOrEqualTo(48),
            reason: texto,
          );
        }
      });

      testWidgets('o card abre o detalhe com o evento, sem o "em breve"', (
        tester,
      ) async {
        final evento = eventoDeTeste(titulo: 'Torneio', descricao: 'Curta.');
        final rotas = <RouteSettings>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: criarTema(),
            onGenerateRoute: (settings) {
              rotas.add(settings);
              return MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('detalhe')),
              );
            },
            home: Scaffold(
              body: SizedBox(width: 320, child: EventoCard(evento: evento)),
            ),
          ),
        );

        await tester.tap(find.byType(EventoCard));
        await tester.pumpAndSettle();

        expect(rotas.last.name, '/evento/detalhe');
        expect(rotas.last.arguments, same(evento));
        expect(find.text('detalhe'), findsOneWidget);
        expect(find.textContaining('em breve'), findsNothing);
      });
    });
  }
}
