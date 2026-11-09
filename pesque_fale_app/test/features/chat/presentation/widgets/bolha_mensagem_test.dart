import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/chat/domain/mensagem.dart';
import 'package:pesque_fale_app/features/chat/presentation/widgets/bolha_mensagem.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Mensagem mensagem({
    required String userId,
    required StatusMensagem status,
  }) => Mensagem(
    id: 'm1',
    chatId: 'u1_u2',
    userId: userId,
    nome: 'Ana',
    texto: 'Oi',
    status: status,
    criadoEm: DateTime(2026, 5, 28, 9, 5),
  );

  Future<void> montar(
    WidgetTester tester, {
    required Mensagem mensagem,
    required bool ehMinha,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: BolhaMensagem(mensagem: mensagem, ehMinha: ehMinha),
        ),
      ),
    );
  }

  testWidgets('mostra done quando propria e enviada', (tester) async {
    await montar(
      tester,
      mensagem: mensagem(userId: 'eu', status: StatusMensagem.enviado),
      ehMinha: true,
    );

    expect(find.byIcon(Icons.done), findsOneWidget);
    expect(find.byIcon(Icons.done_all), findsNothing);
  });

  testWidgets('mostra done_all quando propria e vista', (tester) async {
    await montar(
      tester,
      mensagem: mensagem(userId: 'eu', status: StatusMensagem.visto),
      ehMinha: true,
    );

    expect(find.byIcon(Icons.done_all), findsOneWidget);
  });

  testWidgets('nao mostra icone de status quando nao e propria', (
    tester,
  ) async {
    await montar(
      tester,
      mensagem: mensagem(userId: 'outro', status: StatusMensagem.visto),
      ehMinha: false,
    );

    expect(find.byIcon(Icons.done), findsNothing);
    expect(find.byIcon(Icons.done_all), findsNothing);
  });

  testWidgets('mostra a hora formatada', (tester) async {
    await montar(
      tester,
      mensagem: mensagem(userId: 'eu', status: StatusMensagem.enviado),
      ehMinha: true,
    );

    expect(find.text('09:05'), findsOneWidget);
  });
}
