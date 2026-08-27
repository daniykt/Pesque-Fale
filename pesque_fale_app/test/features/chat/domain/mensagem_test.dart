import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/chat/domain/mensagem.dart';

void main() {
  group('Mensagem.fromJson', () {
    test('mapeia status "enviado" corretamente', () {
      final mensagem = Mensagem.fromJson({
        'id': 'm1',
        'chatId': 'u1_u2',
        'userId': 'u1',
        'nome': 'Ana',
        'texto': 'Oi',
        'status': 'enviado',
        'criadoEm': '2026-05-28T09:50:00Z',
      });

      expect(mensagem.status, StatusMensagem.enviado);
      expect(mensagem.texto, 'Oi');
    });

    test('mapeia status "visto" corretamente', () {
      final mensagem = Mensagem.fromJson({
        'id': 'm1',
        'chatId': 'u1_u2',
        'userId': 'u1',
        'nome': 'Ana',
        'texto': 'Oi',
        'status': 'visto',
        'criadoEm': '2026-05-28T09:50:00Z',
      });

      expect(mensagem.status, StatusMensagem.visto);
    });
  });

  group('Mensagem.copyWith', () {
    final base = Mensagem(
      id: 'm1',
      chatId: 'u1_u2',
      userId: 'u1',
      nome: 'Ana',
      texto: 'Oi',
      status: StatusMensagem.enviado,
      criadoEm: DateTime(2026, 5, 28, 9, 50),
    );

    test('atualiza apenas o status, preservando o resto', () {
      final atualizado = base.copyWith(status: StatusMensagem.visto);

      expect(atualizado.status, StatusMensagem.visto);
      expect(atualizado.id, base.id);
      expect(atualizado.texto, base.texto);
    });
  });
}
