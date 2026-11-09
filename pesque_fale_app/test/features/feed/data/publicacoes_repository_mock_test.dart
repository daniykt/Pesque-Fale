import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_repository_mock.dart';

void main() {
  group('PublicacoesRepositoryMock', () {
    test(
      'lista publicações variadas com imagem/tags/curtidas mistas',
      () async {
        final repo = PublicacoesRepositoryMock();
        final result = await repo.listar(pagina: 1, porPagina: 20);

        expect(result.items, hasLength(12));
        expect(result.items.any((p) => p.imagemUrl != null), isTrue);
        expect(result.items.any((p) => p.imagemUrl == null), isTrue);
        expect(result.items.any((p) => p.tags.isNotEmpty), isTrue);
        expect(result.items.any((p) => p.tags.isEmpty), isTrue);
        expect(result.items.any((p) => p.jaCurtiu), isTrue);
      },
    );

    test(
      'seguindo=true retorna apenas o subconjunto de quem eu sigo',
      () async {
        final repo = PublicacoesRepositoryMock();
        final result = await repo.listar(
          pagina: 1,
          porPagina: 20,
          seguindo: true,
        );

        expect(result.items, hasLength(3));
      },
    );

    test('deletar remove a publicação das listagens seguintes', () async {
      final repo = PublicacoesRepositoryMock();
      final antes = await repo.listar(pagina: 1, porPagina: 20);
      final idRemovido = antes.items.first.id;

      await repo.deletar(idRemovido);

      final depois = await repo.listar(pagina: 1, porPagina: 20);
      expect(depois.items.any((p) => p.id == idRemovido), isFalse);
      expect(depois.total, antes.total - 1);
    });
  });
}
