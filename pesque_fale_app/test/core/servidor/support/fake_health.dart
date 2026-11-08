import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pesque_fale_app/core/servidor/health_api_client.dart';
import 'package:pesque_fale_app/core/servidor/servidor_status_provider.dart';

/// `/health` controlado pelo teste: cada chamada fica pendurada até o teste
/// responder (ou estoura o timeout da tentativa, se ninguém responder).
class FakeHealth {
  final List<Completer<http.Response>> _pendentes = [];

  int get chamadas => _pendentes.length;

  late final HealthApiClient client = HealthApiClient(
    apiBaseUrl: 'https://api.teste/v1',
    client: MockClient((_) {
      final resposta = Completer<http.Response>();
      _pendentes.add(resposta);
      return resposta.future;
    }),
  );

  /// Responde a chamada mais recente.
  void responder([int status = 200]) =>
      _pendentes.last.complete(http.Response('{"status":"ok"}', status));

  /// Provider com os tempos de produção, já iniciado.
  ServidorStatusProvider criarProvider() =>
      ServidorStatusProvider(client: client)..iniciar();
}
