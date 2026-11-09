import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';

void main() {
  group('Publicacao.fromJson', () {
    test('lê todos os campos quando presentes', () {
      final publicacao = Publicacao.fromJson({
        'id': '1',
        'autorId': 'user-1',
        'autorNome': 'Ana',
        'imagemUrl': 'https://x/foto.png',
        'descricao': 'Pescaria de sábado',
        'tags': ['tilapia', 'lago'],
        'curtidasCount': 10,
        'comentariosCount': 2,
        'jaCurtiu': true,
        'criadoEm': '2026-01-01T00:00:00.000Z',
        'atualizadoEm': '2026-01-02T00:00:00.000Z',
      });

      expect(publicacao.id, '1');
      expect(publicacao.autorId, 'user-1');
      expect(publicacao.autorNome, 'Ana');
      expect(publicacao.imagemUrl, 'https://x/foto.png');
      expect(publicacao.descricao, 'Pescaria de sábado');
      expect(publicacao.tags, ['tilapia', 'lago']);
      expect(publicacao.curtidasCount, 10);
      expect(publicacao.comentariosCount, 2);
      expect(publicacao.jaCurtiu, isTrue);
      expect(publicacao.criadoEm, DateTime.utc(2026, 1, 1));
      expect(publicacao.atualizadoEm, DateTime.utc(2026, 1, 2));
    });

    test('usa defaults quando campos opcionais faltam', () {
      final publicacao = Publicacao.fromJson({'id': '2', 'autorId': 'user-2'});

      expect(publicacao.autorNome, '');
      expect(publicacao.imagemUrl, isNull);
      expect(publicacao.descricao, isNull);
      expect(publicacao.tags, isEmpty);
      expect(publicacao.curtidasCount, 0);
      expect(publicacao.comentariosCount, 0);
      expect(publicacao.jaCurtiu, isFalse);
    });
  });
}
