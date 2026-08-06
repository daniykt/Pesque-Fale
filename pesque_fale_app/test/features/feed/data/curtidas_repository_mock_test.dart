import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/feed/data/curtidas_repository_mock.dart';

void main() {
  group('CurtidasRepositoryMock', () {
    test('curtir é idempotente: chamar duas vezes não duplica', () async {
      final repo = CurtidasRepositoryMock();

      await repo.curtir('pub-1');
      await repo.curtir('pub-1');

      expect(repo.curtidas.where((id) => id == 'pub-1').length, 1);
    });

    test('descurtir remove a curtida', () async {
      final repo = CurtidasRepositoryMock();

      await repo.curtir('pub-1');
      await repo.descurtir('pub-1');

      expect(repo.curtidas.contains('pub-1'), isFalse);
    });

    test('descurtir sem ter curtido antes não lança erro', () async {
      final repo = CurtidasRepositoryMock();
      await repo.descurtir('pub-nunca-curtida');
      expect(repo.curtidas.contains('pub-nunca-curtida'), isFalse);
    });
  });
}
