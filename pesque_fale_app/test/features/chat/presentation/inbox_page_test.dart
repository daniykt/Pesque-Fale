import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/chat/data/conversas_repository.dart';
import 'package:pesque_fale_app/features/chat/domain/conversa.dart';
import 'package:pesque_fale_app/features/chat/presentation/inbox_page.dart';
import 'package:pesque_fale_app/features/chat/presentation/widgets/badge_nao_lidas.dart';
import 'package:pesque_fale_app/features/chat/presentation/widgets/item_conversa.dart';
import 'package:pesque_fale_app/features/chat/providers/inbox_provider.dart';

class _FakeConversasRepository implements ConversasRepository {
  _FakeConversasRepository(this.conversas);

  List<Conversa> conversas;

  @override
  Future<List<Conversa>> listar() async => conversas;
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

/// Substitui a ChatPage real (que abre socket e lê token) — o que está em
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

  Future<void> montar(WidgetTester tester, ConversasRepository repository) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ChangeNotifierProvider(
          create: (_) => InboxProvider(repository: repository),
          child: const InboxPage(),
        ),
        onGenerateRoute: (settings) => settings.name == '/chat/conversa'
            ? MaterialPageRoute(builder: (_) => const _ChatFalsa())
            : null,
      ),
    );
  }

  testWidgets(
    'ao voltar da conversa, recarrega badge de não lidas e última mensagem',
    (tester) async {
      final repository = _FakeConversasRepository([
        _conversa(ultimaMensagem: 'fala comigo', naoLidas: 1),
      ]);

      await montar(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('fala comigo'), findsOneWidget);
      expect(find.byType(BadgeNaoLidas), findsOneWidget);

      // Enquanto a conversa está aberta, o backend marca como visto e o
      // usuário envia uma mensagem nova.
      repository.conversas = [_conversa(ultimaMensagem: 'eeee', naoLidas: 0)];

      await tester.tap(find.byType(ItemConversa));
      await tester.pumpAndSettle();
      expect(find.text('chat falso'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('eeee'), findsOneWidget);
      expect(find.text('fala comigo'), findsNothing);
      expect(find.byType(BadgeNaoLidas), findsNothing);
    },
  );
}
