import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/chat/data/conversas_repository.dart';
import 'package:pesque_fale_app/features/chat/domain/conversa.dart';
import 'package:pesque_fale_app/features/chat/presentation/inbox_page.dart';
import 'package:pesque_fale_app/features/chat/presentation/widgets/badge_nao_lidas.dart';
import 'package:pesque_fale_app/features/chat/presentation/widgets/item_conversa.dart';
import 'package:pesque_fale_app/features/chat/providers/inbox_provider.dart';

import '../support/fake_realtime_manager.dart';

class _FakeConversasRepository implements ConversasRepository {
  _FakeConversasRepository(this.conversas);

  List<Conversa> conversas;
  int chamadas = 0;

  @override
  Future<List<Conversa>> listar() async {
    chamadas++;
    return conversas;
  }
}

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
    accessToken: 'token-eu',
    usuario: Usuario(
      id: 'eu',
      nome: 'Pescador',
      email: email,
      onboardingConcluido: true,
    ),
  );

  @override
  Future<void> logout() async {}
}

Conversa _conversa({required String ultimaMensagem, required int naoLidas}) {
  final agora = DateTime(2026, 9, 29, 10);
  return Conversa(
    id: 'chat-1',
    outroId: 'user-danilodev',
    outroNome: 'Dani dev',
    outroUsername: 'danilodev',
    ultimaMensagem: ultimaMensagem,
    ultimaMensagemEm: agora,
    naoLidas: naoLidas,
    criadoEm: agora,
  );
}

/// Substitui a ChatPage real (que entra no chat pelo socket) — o que está em
/// teste é a InboxPage reagindo ao fechamento da conversa.
class _ChatFalsa extends StatelessWidget {
  const _ChatFalsa();

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('chat falso')));
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late FakeRealtimeManager realtime;
  late AuthProvider auth;

  setUp(() async {
    realtime = FakeRealtimeManager();
    auth = AuthProvider(repository: _FakeAuthRepository());
    await auth.login(email: 'eu@teste.com', senha: '123456');
  });

  Future<void> montar(WidgetTester tester, ConversasRepository repository) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ChangeNotifierProvider(
          // No app o proxy do main.dart chama reagirAuth; aqui o teste faz
          // o papel dele (dispara o load inicial e define o usuário logado).
          create: (_) =>
              InboxProvider(repository: repository, realtime: realtime)
                ..reagirAuth(auth),
          child: const InboxPage(),
        ),
        onGenerateRoute: (settings) => settings.name == '/chat/conversa'
            ? MaterialPageRoute(builder: (_) => const _ChatFalsa())
            : null,
      ),
    );
  }

  testWidgets(
    'ao voltar da conversa o badge já zerou via conversa_lida, sem refresh',
    (tester) async {
      final repository = _FakeConversasRepository([
        _conversa(ultimaMensagem: 'fala comigo', naoLidas: 1),
      ]);

      await montar(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('fala comigo'), findsOneWidget);
      expect(find.byType(BadgeNaoLidas), findsOneWidget);

      await tester.tap(find.byType(ItemConversa));
      await tester.pumpAndSettle();
      expect(find.text('chat falso'), findsOneWidget);

      // Abrir a conversa marca como visto no backend, que avisa o inbox.
      realtime.emitir('conversa_lida', {
        'conversaId': 'chat-1',
        'lidaPor': 'eu',
        'quandoEm': '2026-10-27T12:00:00.000Z',
      });

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('fala comigo'), findsOneWidget);
      expect(find.byType(BadgeNaoLidas), findsNothing);
      expect(repository.chamadas, 1);
    },
  );

  testWidgets(
    'conversa nova aparece na lista vazia sem sair da aba (bug da #183)',
    (tester) async {
      await montar(tester, _FakeConversasRepository([]));
      await tester.pumpAndSettle();
      expect(find.byType(ItemConversa), findsNothing);

      realtime.emitir('nova_conversa', {
        'conversaId': 'chat-1',
        'remetente': {
          'id': 'user-henrique',
          'nome': 'Henrique',
          'username': 'rique',
          'fotoUrl': null,
        },
        'ultimaMensagem': {
          'id': 'msg-1',
          'texto': 'bora pescar?',
          'criadoEm': '2026-10-27T12:00:00.000Z',
        },
      });
      await tester.pump();

      expect(find.byType(ItemConversa), findsOneWidget);
      expect(find.text('bora pescar?'), findsOneWidget);
      expect(find.byType(BadgeNaoLidas), findsOneWidget);
    },
  );
}
