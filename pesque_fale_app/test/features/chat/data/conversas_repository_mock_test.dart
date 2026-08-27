import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/chat/data/conversas_repository_mock.dart';

void main() {
  group('ConversasRepositoryMock', () {
    test('lista conversas incluindo uma sem mensagem ainda', () async {
      final repo = ConversasRepositoryMock();
      final result = await repo.listar();

      expect(result.any((c) => c.ultimaMensagem == null), isTrue);
      expect(result.any((c) => c.temMensagem), isTrue);
    });

    test('inclui conversa com mais de 99 não lidas', () async {
      final repo = ConversasRepositoryMock();
      final result = await repo.listar();

      expect(result.any((c) => c.naoLidas > 99), isTrue);
    });
  });
}
