import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

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
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
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
}
