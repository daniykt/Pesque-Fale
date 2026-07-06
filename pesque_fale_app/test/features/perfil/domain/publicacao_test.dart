import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/perfil/domain/publicacao.dart';

void main() {
  group('Publicacao.fromJson', () {
    test('lê todos os campos quando presentes', () {
      final publicacao = Publicacao.fromJson({
        'id': '1',
        'autorId': 'user-1',
        'imagemUrl': 'https://x/foto.png',
        'legenda': 'Pescaria de sábado',
        'tags': ['tilapia', 'lago'],
        'curtidasCount': 10,
        'comentariosCount': 2,
        'criadoEm': '2026-01-01T00:00:00.000Z',
      });

      expect(publicacao.id, '1');
      expect(publicacao.autorId, 'user-1');
      expect(publicacao.imagemUrl, 'https://x/foto.png');
      expect(publicacao.legenda, 'Pescaria de sábado');
      expect(publicacao.tags, ['tilapia', 'lago']);
      expect(publicacao.curtidasCount, 10);
      expect(publicacao.comentariosCount, 2);
    });

    test('usa defaults quando campos opcionais faltam', () {
      final publicacao = Publicacao.fromJson({
        'id': '2',
        'autorId': 'user-2',
        'imagemUrl': 'https://x/foto2.png',
      });

      expect(publicacao.legenda, isNull);
      expect(publicacao.tags, isEmpty);
      expect(publicacao.curtidasCount, 0);
      expect(publicacao.comentariosCount, 0);
    });
  });
}
