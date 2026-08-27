import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/chat/presentation/widgets/input_mensagem.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montar(
    WidgetTester tester, {
    required ValueChanged<String> onEnviar,
    required ValueChanged<String> onDigitando,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: InputMensagem(onEnviar: onEnviar, onDigitando: onDigitando),
        ),
      ),
    );
  }

  testWidgets('botao de envio inicia desabilitado com campo vazio', (
    tester,
  ) async {
    await montar(tester, onEnviar: (_) {}, onDigitando: (_) {});

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNull);
  });

  testWidgets('digitar texto habilita o botao e chama onDigitando', (
    tester,
  ) async {
    final digitados = <String>[];
    await montar(tester, onEnviar: (_) {}, onDigitando: digitados.add);

    await tester.enterText(find.byType(TextField), 'oi');
    await tester.pump();

    expect(digitados, ['oi']);
    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNotNull);
  });

  testWidgets('tocar enviar chama onEnviar e limpa o campo', (tester) async {
    String? enviado;
    await montar(
      tester,
      onEnviar: (texto) => enviado = texto,
      onDigitando: (_) {},
    );

    await tester.enterText(find.byType(TextField), 'oi tudo bem');
    await tester.pump();
    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(enviado, 'oi tudo bem');
    expect(find.text('oi tudo bem'), findsNothing);
  });

  testWidgets('campo so com espacos mantem botao desabilitado', (
    tester,
  ) async {
    await montar(tester, onEnviar: (_) {}, onDigitando: (_) {});

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNull);
  });
}
