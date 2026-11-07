import '../domain/clima.dart';

abstract class ClimaRepository {
  Future<Clima> buscarAtual({
    required double latitude,
    required double longitude,
  });
}
