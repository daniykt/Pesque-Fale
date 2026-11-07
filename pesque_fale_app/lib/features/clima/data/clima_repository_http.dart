import '../domain/clima.dart';
import 'clima_api_client.dart';
import 'clima_exceptions.dart';
import 'clima_repository.dart';

class ClimaRepositoryHttp implements ClimaRepository {
  ClimaRepositoryHttp({required this.apiClient});

  final ClimaApiClient apiClient;

  @override
  Future<Clima> buscarAtual({
    required double latitude,
    required double longitude,
  }) async {
    final json = await apiClient.buscarAtual(
      latitude: latitude,
      longitude: longitude,
    );
    try {
      return Clima.fromOpenMeteo(json);
    } on FormatException {
      throw const ClimaServicoException();
    }
  }
}
