import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/shared/widgets/badge_equipe/tipo_badge.dart';

void main() {
  group('resolverBadge', () {
    test('devolve dev pra todo UUID da lista de devs', () {
      for (final id in idsDevs) {
        expect(resolverBadge(id), TipoBadge.dev, reason: id);
      }
    });

    test('devolve oficial pra UUID da conta oficial', () {
      for (final id in idsOficial) {
        expect(resolverBadge(id), TipoBadge.oficial, reason: id);
      }
    });

    test('devolve null pra UUID de usuario comum', () {
      expect(resolverBadge('00000000-0000-0000-0000-000000000000'), isNull);
    });

    test('devolve null pra string vazia e null', () {
      expect(resolverBadge(''), isNull);
      expect(resolverBadge(null), isNull);
    });

    test('listas tem 3 devs e 1 oficial, sem sobreposicao', () {
      expect(idsDevs, hasLength(3));
      expect(idsOficial, hasLength(1));
      expect(idsDevs.intersection(idsOficial), isEmpty);
    });
  });
}
