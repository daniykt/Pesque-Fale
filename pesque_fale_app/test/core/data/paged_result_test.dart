import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/core/data/paged_result.dart';

void main() {
  group('PagedResult.temMais', () {
    test('true quando existem itens além da página atual', () {
      const result = PagedResult<int>(
        items: [1, 2, 3],
        total: 10,
        pagina: 1,
        porPagina: 3,
      );
      expect(result.temMais, isTrue);
    });

    test('false na última página exata', () {
      const result = PagedResult<int>(
        items: [1, 2, 3, 4],
        total: 12,
        pagina: 3,
        porPagina: 4,
      );
      expect(result.temMais, isFalse);
    });

    test('false na primeira página quando ela já cobre todo o total', () {
      const result = PagedResult<int>(
        items: [1, 2],
        total: 2,
        pagina: 1,
        porPagina: 20,
      );
      expect(result.temMais, isFalse);
    });

    test('false quando o resultado está vazio', () {
      const result = PagedResult<int>(
        items: [],
        total: 0,
        pagina: 1,
        porPagina: 20,
      );
      expect(result.temMais, isFalse);
    });
  });
}
