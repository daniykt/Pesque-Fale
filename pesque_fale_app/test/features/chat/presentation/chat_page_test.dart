import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/chat/domain/conversa.dart';
import 'package:pesque_fale_app/features/chat/presentation/chat_page.dart';
import 'package:pesque_fale_app/features/chat/presentation/widgets/chat_app_bar.dart';
import 'package:pesque_fale_app/features/chat/presentation/widgets/input_mensagem.dart';
import 'package:pesque_fale_app/features/chat/presentation/widgets/skeleton_mensagens.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  TestWidgetsFlutterBinding.ensureInitialized();

  const canalSecureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          canalSecureStorage,
          (_) => Completer<Object?>().future,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalSecureStorage, null);
  });

  final conversa = Conversa(
    id: 'u1_u2',
    outroId: 'u2',
    outroNome: 'Guilherme Souza',
    outroUsername: 'guilhermino',
    naoLidas: 0,
    criadoEm: DateTime(2026, 9, 1),
  );

  testWidgets(
    'sem histórico carregado mostra a estrutura da conversa com skeleton',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ChatPage(conversa: conversa),
        ),
      );
      await tester.pump();

      expect(find.byType(SkeletonMensagens), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ChatAppBar), findsOneWidget);
      expect(find.byType(InputMensagem), findsOneWidget);
    },
  );
}