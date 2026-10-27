import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/realtime/realtime_manager.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/chat/domain/conversa.dart';
import 'package:pesque_fale_app/features/chat/presentation/chat_page.dart';
import 'package:pesque_fale_app/features/chat/presentation/widgets/chat_app_bar.dart';
import 'package:pesque_fale_app/features/chat/presentation/widgets/input_mensagem.dart';
import 'package:pesque_fale_app/features/chat/presentation/widgets/skeleton_mensagens.dart';

import '../support/fake_realtime_manager.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) async => throw UnimplementedError();

  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async => AuthResult(
    accessToken: 'token-u1',
    usuario: Usuario(
      id: 'u1',
      nome: 'Pescador',
      email: email,
      onboardingConcluido: true,
    ),
  );

  @override
  Future<void> logout() async {}
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  final conversa = Conversa(
    id: 'u1_u2',
    outroId: 'u2',
    outroNome: 'Guilherme Souza',
    outroUsername: 'guilhermino',
    naoLidas: 0,
    criadoEm: DateTime(2026, 9, 1),
  );

  late FakeRealtimeManager realtime;
  late AuthProvider auth;

  setUp(() async {
    realtime = FakeRealtimeManager(conectado: true);
    auth = AuthProvider(repository: _FakeAuthRepository());
    await auth.login(email: 'u1@teste.com', senha: '123456');
  });

  Future<void> montar(WidgetTester tester) => tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<RealtimeManager>.value(value: realtime),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: ChatPage(conversa: conversa),
      ),
    ),
  );

  testWidgets(
    'sem histórico carregado mostra a estrutura da conversa com skeleton',
    (tester) async {
      await montar(tester);
      await tester.pump();

      expect(find.byType(SkeletonMensagens), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ChatAppBar), findsOneWidget);
      expect(find.byType(InputMensagem), findsOneWidget);
    },
  );

  testWidgets('entra no chat pelo socket global e sai limpando as assinaturas', (
    tester,
  ) async {
    await montar(tester);

    expect(realtime.emitidos.single.key, 'entrar_chat');
    expect(realtime.emitidos.single.value, {'outroId': 'u2'});
    expect(realtime.assinantes['historico'], hasLength(1));

    await tester.pumpWidget(const SizedBox());

    expect(realtime.assinantes['historico'], isEmpty);
    expect(realtime.temOuvintes, isFalse);
  });
}
