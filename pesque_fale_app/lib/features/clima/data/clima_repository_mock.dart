import '../domain/clima.dart';
import '../domain/condicao_clima.dart';
import 'clima_repository.dart';

class ClimaRepositoryMock implements ClimaRepository {
  static const _delay = Duration(milliseconds: 600);

  @override
  Future<Clima> buscarAtual({
    required double latitude,
    required double longitude,
  }) async {
    await Future.delayed(_delay);
    return const Clima(
      temperatura: 24.5,
      umidade: 70,
      ventoKmh: 9.4,
      condicao: CondicaoClima.parcialmenteNublado,
    );
  }
}
