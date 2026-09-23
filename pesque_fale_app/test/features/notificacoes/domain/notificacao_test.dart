import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/notificacoes/domain/notificacao.dart';

Map<String, dynamic> _json({Object? deVolta, bool incluirDeVolta = true}) => {
  'id': 'notif-1',
  'para': 'eu',
  'deId': 'outro',
  'de': 'Outro Pescador',
  'deUsername': 'outro',
  'deFoto': null,
  'jaSigoDe': false,
  'tipo': 'seguindo',
  'texto': null,
  'postId': null,
  'chatId': null,
  'lida': false,
  'criadoEm': '2026-01-01T00:00:00.000Z',
  if (incluirDeVolta) 'deVolta': deVolta,
};

void main() {
  group('Notificacao.fromJson — deVolta', () {
    test('lê deVolta true', () {
      final n = Notificacao.fromJson(_json(deVolta: true));
      expect(n.deVolta, isTrue);
    });

    test('lê deVolta false', () {
      final n = Notificacao.fromJson(_json(deVolta: false));
      expect(n.deVolta, isFalse);
    });

    test('assume false quando a API não manda a chave', () {
      final n = Notificacao.fromJson(_json(incluirDeVolta: false));
      expect(n.deVolta, isFalse);
    });
  });

  group('Notificacao.copyWith', () {
    test('preserva deVolta ao alterar lida e jaSigoDe', () {
      final original = Notificacao.fromJson(_json(deVolta: true));

      final copia = original.copyWith(lida: true, jaSigoDe: true);

      expect(copia.deVolta, isTrue);
      expect(copia.lida, isTrue);
      expect(copia.jaSigoDe, isTrue);
    });
  });
}
