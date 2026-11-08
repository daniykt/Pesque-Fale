import 'package:http/http.dart' as http;

/// Chama o `GET /health` da API, que fica na raiz do servidor, fora do `/v1`.
class HealthApiClient {
  HealthApiClient({required String apiBaseUrl, http.Client? client})
    : uri = uriDoHealth(apiBaseUrl),
      _client = client ?? http.Client();

  final Uri uri;
  final http.Client _client;

  /// `https://host/v1` → `https://host/health`.
  static Uri uriDoHealth(String apiBaseUrl) =>
      Uri.parse(apiBaseUrl).replace(path: '/health');

  /// `true` com resposta 2xx. Erro de rede e [timeout] sobem como exceção.
  Future<bool> checar({required Duration timeout}) async {
    final resposta = await _client.get(uri).timeout(timeout);
    return resposta.statusCode >= 200 && resposta.statusCode < 300;
  }
}
