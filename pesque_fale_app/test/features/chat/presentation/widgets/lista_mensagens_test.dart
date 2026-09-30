import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/chat/domain/mensagem.dart';
import 'package:pesque_fale_app/features/chat/presentation/widgets/divisor_data.dart';
import 'package:pesque_fale_app/features/chat/presentation/widgets/indicador_digitando.dart';
import 'package:pesque_fale_app/features/chat/presentation/widgets/lista_mensagens.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Mensagem mensagem({
    required String id,
    required String userId,
    required DateTime criadoEm,
  }) => Mensagem(
    id: id,
    chatId: 'u1_u2',
    userId: userId,
    nome: 'Ana',
    texto: 'Mensagem $id',
    status: StatusMensagem.enviado,
    criadoEm: criadoEm,
  );

  Future<void> montar(
    WidgetTester tester, {
    required List<Mensagem> mensagens,
    bool outroDigitando = false,
    ThemeData? tema,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: tema ?? AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: ListaMensagens(
              mensagens: mensagens,
              usuarioLogadoId: 'eu',
              outroDigitando: outroDigitando,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('agrupa mensagens de dias diferentes com divisores', (
    tester,
  ) async {
    await montar(
      tester,
      mensagens: [
        mensagem(id: '1', userId: 'eu', criadoEm: DateTime(2026, 5, 27, 10)),
        mensagem(id: '2', userId: 'outro', criadoEm: DateTime(2026, 5, 27, 11)),
        mensagem(id: '3', userId: 'eu', criadoEm: DateTime(2026, 5, 28, 9)),
      ],
    );
    await tester.pump();

    expect(find.byType(DivisorData), findsNWidgets(2));
  });

  testWidgets('mensagens do mesmo dia ficam sob um unico divisor', (
    tester,
  ) async {
    await montar(
      tester,
      mensagens: [
        mensagem(id: '1', userId: 'eu', criadoEm: DateTime(2026, 5, 28, 9)),
        mensagem(id: '2', userId: 'outro', criadoEm: DateTime(2026, 5, 28, 10)),
        mensagem(id: '3', userId: 'eu', criadoEm: DateTime(2026, 5, 28, 11)),
      ],
    );
    await tester.pump();

    expect(find.byType(DivisorData), findsOneWidget);
  });

  testWidgets('mostra indicador de digitando quando outroDigitando e true', (
    tester,
  ) async {
    await montar(
      tester,
      mensagens: [
        mensagem(id: '1', userId: 'eu', criadoEm: DateTime(2026, 5, 28, 9)),
      ],
      outroDigitando: true,
    );
    await tester.pump();

    expect(find.byType(IndicadorDigitando), findsOneWidget);
  });

  testWidgets('nao mostra indicador de digitando quando false', (
    tester,
  ) async {
    await montar(
      tester,
      mensagens: [
        mensagem(id: '1', userId: 'eu', criadoEm: DateTime(2026, 5, 28, 9)),
      ],
    );
    await tester.pump();

    expect(find.byType(IndicadorDigitando), findsNothing);
  });

  group('botão de ir para a última mensagem', () {
    final botao = find.byTooltip('Ir para a última mensagem');

    List<Mensagem> muitasMensagens() => List.generate(
      40,
      (i) => mensagem(
        id: '$i',
        userId: i.isEven ? 'eu' : 'outro',
        criadoEm: DateTime(2026, 5, 28, 9, i),
      ),
    );

    double opacidadeDoBotao(WidgetTester tester) => tester
        .widget<AnimatedOpacity>(
          find.ancestor(of: botao, matching: find.byType(AnimatedOpacity)),
        )
        .opacity;

    double distanciaDoFim(WidgetTester tester) {
      final posicao = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      return posicao.maxScrollExtent - posicao.pixels;
    }

    Future<void> montarNoFim(WidgetTester tester, {ThemeData? tema}) async {
      await montar(tester, mensagens: muitasMensagens(), tema: tema);
      await tester.pumpAndSettle();
    }

    testWidgets('fica escondido ao abrir a conversa no fim', (tester) async {
      await montarNoFim(tester);

      expect(distanciaDoFim(tester), lessThan(1));
      expect(opacidadeDoBotao(tester), 0);
    });

    testWidgets('aparece ao rolar para cima além do limite', (tester) async {
      await montarNoFim(tester);

      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pumpAndSettle();

      expect(opacidadeDoBotao(tester), 1);
    });

    testWidgets('continua escondido numa rolagem pequena', (tester) async {
      await montarNoFim(tester);

      await tester.drag(find.byType(ListView), const Offset(0, 120));
      await tester.pumpAndSettle();

      expect(opacidadeDoBotao(tester), 0);
    });

    testWidgets('ao tocar, desce até a última mensagem e some', (
      tester,
    ) async {
      await montarNoFim(tester);
      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pumpAndSettle();

      await tester.tap(botao);
      await tester.pumpAndSettle();

      expect(distanciaDoFim(tester), lessThan(1));
      expect(opacidadeDoBotao(tester), 0);
    });

    testWidgets('some ao voltar ao fim rolando manualmente', (tester) async {
      await montarNoFim(tester);
      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(opacidadeDoBotao(tester), 0);
    });

    testWidgets('no tema escuro usa a cor de destaque clara', (tester) async {
      await montarNoFim(tester, tema: AppTheme.dark);

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );

      expect(fab.backgroundColor, AppColors.dark.primaryAccent);
      expect(fab.foregroundColor, AppColors.dark.primary);
    });
  });
}