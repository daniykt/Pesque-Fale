import 'curtidas_repository.dart';

class CurtidasRepositoryMock implements CurtidasRepository {
  static const _delay = Duration(milliseconds: 200);

  final Set<String> curtidas = {};

  @override
  Future<void> curtir(String publicacaoId) async {
    await Future.delayed(_delay);
    curtidas.add(publicacaoId);
  }

  @override
  Future<void> descurtir(String publicacaoId) async {
    await Future.delayed(_delay);
    curtidas.remove(publicacaoId);
  }
}
