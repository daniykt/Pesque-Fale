import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/clima/data/clima_exceptions.dart';
import 'package:pesque_fale_app/features/clima/data/clima_repository.dart';
import 'package:pesque_fale_app/features/clima/data/localizacao_service.dart';
import 'package:pesque_fale_app/features/clima/domain/clima.dart';
import 'package:pesque_fale_app/features/clima/domain/condicao_clima.dart';
import 'package:pesque_fale_app/features/clima/providers/clima_provider.dart';
import 'package:pesque_fale_app/features/feed/presentation/widgets/clima_card.dart';

class _Repo implements ClimaRepository {
  Object? erro;
  Completer<void>? segurar;
  int chamadas = 0;

  @override
  Future<Clima> buscarAtual({
    required double latitude,
    required double longitude,
  }) async {
    chamadas++;
    await segurar?.future;
    final e = erro;
    if (e != null) throw e;
    return const Clima(
      temperatura: 18.4,
      umidade: 92,
      ventoKmh: 14.6,
      condicao: CondicaoClima.garoa,
    );
  }
}

class _Localizacao implements LocalizacaoService {
  ResultadoLocalizacao resultado = const LocalizacaoObtida(
    latitude: -21.6,
    longitude: -48.36,
  );
  final List<MotivoSemLocalizacao> configuracoesAbertas = [];

  @override
  Future<ResultadoLocalizacao> obter({required bool pedirPermissao}) async =>
      resultado;

  @override
  Future<void> abrirConfiguracoes(MotivoSemLocalizacao motivo) async {
    configuracoesAbertas.add(motivo);
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final (nomeTema, criarTema) in [
    ('claro', () => AppTheme.light),
    ('escuro', () => AppTheme.dark),
  ]) {
    group('tema $nomeTema', () {
      late _Repo repo;
      late _Localizacao localizacao;
      late ClimaProvider provider;
      late ThemeData tema;

      Future<void> montar(WidgetTester tester) async {
        tema = criarTema();
        await tester.pumpWidget(
          ChangeNotifierProvider<ClimaProvider>.value(
            value: provider,
            child: MaterialApp(
              theme: tema,
              home: const Scaffold(
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: ClimaCard(),
                ),
              ),
            ),
          ),
        );
      }

      setUp(() {
        repo = _Repo();
        localizacao = _Localizacao();
        provider = ClimaProvider(
          repository: repo,
          localizacao: localizacao,
          agora: () => DateTime(2026, 11, 6, 9),
        );
      });

      testWidgets('carregando mostra o skeleton, sem números de clima', (
        tester,
      ) async {
        repo.segurar = Completer<void>();
        await montar(tester);
        unawaited(provider.abrir());
        await tester.pump();

        expect(find.bySemanticsLabel('Carregando o clima'), findsOneWidget);
        expect(find.textContaining('°C'), findsNothing);

        repo.segurar!.complete();
        await tester.pumpAndSettle();
      });

      testWidgets(
        'sucesso mostra data, temperatura, condição, vento e umidade',
        (tester) async {
          await montar(tester);
          await provider.abrir();
          await tester.pumpAndSettle();

          expect(find.text('Clima agora'), findsOneWidget);
          expect(find.text('Sexta-feira, 6 de novembro'), findsOneWidget);
          expect(find.text('18°C'), findsOneWidget);
          expect(find.text('Garoa'), findsOneWidget);
          expect(find.text('Vento: 15 km/h'), findsOneWidget);
          expect(find.text('Umidade: 92%'), findsOneWidget);
          expect(find.textContaining('Melhor período'), findsNothing);
          expect(find.textContaining('Condições ótimas'), findsNothing);

          final temperatura = tester.widget<Text>(find.text('18°C'));
          expect(
            temperatura.style!.color,
            tema.extension<AppColors>()!.primaryAccent,
          );
          expect(temperatura.style!.fontSize, greaterThanOrEqualTo(32));
          expect(tester.takeException(), isNull);
        },
      );

      for (final (motivo, rotulo) in [
        (MotivoSemLocalizacao.negada, 'Permitir localização'),
        (MotivoSemLocalizacao.negadaParaSempre, 'Abrir configurações'),
        (MotivoSemLocalizacao.servicoDesligado, 'Ativar localização'),
      ]) {
        testWidgets('sem localização ($motivo) explica e oferece "$rotulo"', (
          tester,
        ) async {
          localizacao.resultado = LocalizacaoIndisponivel(motivo);
          await montar(tester);
          await provider.abrir();
          await tester.pumpAndSettle();

          expect(find.textContaining('°C'), findsNothing);
          expect(find.textContaining('localização'), findsWidgets);
          final botao = find.widgetWithText(OutlinedButton, rotulo);
          expect(botao, findsOneWidget);
          expect(tester.getSize(botao).height, greaterThanOrEqualTo(48));

          localizacao.resultado = const LocalizacaoObtida(
            latitude: -21.6,
            longitude: -48.36,
          );
          await tester.tap(botao);
          await tester.pumpAndSettle();

          if (motivo != MotivoSemLocalizacao.negada) {
            expect(localizacao.configuracoesAbertas, [motivo]);
          }
          expect(find.text('18°C'), findsOneWidget);
        });
      }

      testWidgets('erro mostra a mensagem e "Tentar de novo" busca de novo', (
        tester,
      ) async {
        repo.erro = const ClimaRedeException();
        await montar(tester);
        await provider.abrir();
        await tester.pumpAndSettle();

        expect(find.text(const ClimaRedeException().message), findsOneWidget);
        expect(find.textContaining('°C'), findsNothing);
        final botao = find.widgetWithText(OutlinedButton, 'Tentar de novo');
        expect(tester.getSize(botao).height, greaterThanOrEqualTo(48));

        repo.erro = null;
        await tester.tap(botao);
        await tester.pumpAndSettle();

        expect(repo.chamadas, 2);
        expect(find.text('18°C'), findsOneWidget);
      });

      testWidgets('em 360dp com fonte 1.3 não estoura o layout', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        localizacao.resultado = const LocalizacaoIndisponivel(
          MotivoSemLocalizacao.negadaParaSempre,
        );

        await montar(tester);
        await provider.abrir();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        localizacao.resultado = const LocalizacaoObtida(
          latitude: -21.6,
          longitude: -48.36,
        );
        await provider.atualizar();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });
  }
}
