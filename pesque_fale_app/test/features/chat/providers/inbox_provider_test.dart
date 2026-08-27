import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/chat/data/conversas_repository.dart';
import 'package:pesque_fale_app/features/chat/domain/conversa.dart';
import 'package:pesque_fale_app/features/chat/providers/inbox_provider.dart';

class _FakeConversasRepository implements ConversasRepository {
  _FakeConversasRepository({this.conversas = const [], this.falhar = false});

  List<Conversa> conversas;
  bool falhar;

  @override
  Future<List<Conversa>> listar() async {
    if (falhar) throw Exception('erro');
    return conversas;
  }
}

Conversa _conversa({
  required String id,
  required String nome,
  required String username,
  String? ultimaMensagem = 'oi',
  int naoLidas = 0,
}) {
  final agora = DateTime(2026, 5, 28);
  return Conversa(
    id: id,
    outroId: 'user-$id',
    outroNome: nome,
    outroUsername: username,
    ultimaMensagem: ultimaMensagem,
    ultimaMensagemEm: ultimaMensagem != null ? agora : null,
    naoLidas: naoLidas,
    criadoEm: agora,
  );
}

void main() {
  group('InboxProvider', () {
    test('carregar popula conversas e filtra chats vazios', () async {
      final repo = _FakeConversasRepository(
        conversas: [
          _conversa(id: '1', nome: 'Henrique Tavares', username: 'rique'),
          _conversa(
            id: '2',
            nome: 'João Pedro',
            username: 'joaop',
            ultimaMensagem: null,
          ),
        ],
      );
      final provider = InboxProvider(repository: repo);

      await provider.carregar();

      expect(provider.status, StatusInbox.carregado);
      expect(provider.conversas, hasLength(1));
      expect(provider.temAlgumaConversa, isTrue);
    });

    test('carregar com falha define status de erro', () async {
      final provider = InboxProvider(
        repository: _FakeConversasRepository(falhar: true),
      );

      await provider.carregar();

      expect(provider.status, StatusInbox.erro);
    });

    test('busca filtra por nome ou username, case-insensitive', () async {
      final repo = _FakeConversasRepository(
        conversas: [
          _conversa(id: '1', nome: 'Henrique Tavares', username: 'rique'),
          _conversa(id: '2', nome: 'Beatriz Fisher', username: 'bia_fisher'),
        ],
      );
      final provider = InboxProvider(repository: repo);
      await provider.carregar();

      provider.setTermoBusca('HENRIQUE');
      expect(provider.conversas.map((c) => c.id), ['1']);

      provider.setTermoBusca('bia_fisher');
      expect(provider.conversas.map((c) => c.id), ['2']);

      provider.setTermoBusca('inexistente');
      expect(provider.conversas, isEmpty);

      provider.setTermoBusca('');
      expect(provider.conversas, hasLength(2));
    });

    test('refresh mantém dados anteriores quando falha', () async {
      final repo = _FakeConversasRepository(
        conversas: [_conversa(id: '1', nome: 'Ana', username: 'ana')],
      );
      final provider = InboxProvider(repository: repo);
      await provider.carregar();

      repo.falhar = true;
      await provider.refresh();

      expect(provider.status, StatusInbox.carregado);
      expect(provider.conversas, hasLength(1));
    });
  });
}
