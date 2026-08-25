import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/feed/data/comentarios_repository_mock.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_exceptions.dart';

void main() {
  group('ComentariosRepositoryMock', () {
    test('lista comentários paginados de uma publicação semeada', () async {
      final repo = ComentariosRepositoryMock();

      final pagina1 = await repo.listar('pub-0', pagina: 1, porPagina: 5);
      expect(pagina1.items, hasLength(5));
      expect(pagina1.total, 7);
      expect(pagina1.temMais, isTrue);

      final pagina2 = await repo.listar('pub-0', pagina: 2, porPagina: 5);
      expect(pagina2.items, hasLength(2));
      expect(pagina2.temMais, isFalse);
    });

    test('publicação sem comentários retorna lista vazia', () async {
      final repo = ComentariosRepositoryMock();
      final result = await repo.listar('pub-sem-comentarios');
      expect(result.items, isEmpty);
      expect(result.total, 0);
    });

    test('criar valida o texto (1 a 500 caracteres)', () async {
      final repo = ComentariosRepositoryMock();

      expect(
        () => repo.criar('pub-0', ''),
        throwsA(isA<TextoInvalidoException>()),
      );
      expect(
        () => repo.criar('pub-0', 'a' * 501),
        throwsA(isA<TextoInvalidoException>()),
      );
    });

    test('criar insere o novo comentário no topo da lista', () async {
      final repo = ComentariosRepositoryMock();
      final antes = await repo.listar('pub-0', porPagina: 20);

      final criado = await repo.criar('pub-0', 'Ótima pescaria!');

      final depois = await repo.listar('pub-0', porPagina: 20);
      expect(depois.total, antes.total + 1);
      expect(depois.items.first.id, criado.id);
      expect(depois.items.first.texto, 'Ótima pescaria!');
    });

    test('deletar remove o comentário da lista', () async {
      final repo = ComentariosRepositoryMock();
      final antes = await repo.listar('pub-0', porPagina: 20);
      final idRemovido = antes.items.first.id;

      await repo.deletar(idRemovido);

      final depois = await repo.listar('pub-0', porPagina: 20);
      expect(depois.items.any((c) => c.id == idRemovido), isFalse);
      expect(depois.total, antes.total - 1);
    });
  });
}
