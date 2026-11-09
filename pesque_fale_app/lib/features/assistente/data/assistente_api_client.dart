import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../auth/data/token_storage.dart';
import 'assistente_exceptions.dart';

class AssistenteApiClient {
  AssistenteApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _client;

  static const _timeout = Duration(seconds: 90);

  Future<Map<String, dynamic>> perguntar({
    required String mensagem,
    required List<Map<String, String>> historico,
    String? tela,
  }) async {
    final token = await tokenStorage.readToken();
    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/assistente'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'mensagem': mensagem,
              'historico': historico,
                'tela': ?tela,
            }),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const NetworkException();
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }

    Map<String, dynamic> json;
    try {
      json = response.body.isEmpty
          ? const {}
          : jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      json = const {};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    throw _mapError(response.statusCode);
  }

  AssistenteException _mapError(int statusCode) {
    if (statusCode == 400) return const PerguntaInvalidaException();
    if (statusCode == 401) return const NaoAutenticadoException();
    if (statusCode == 429) return const LimiteAssistenteException();
    if (statusCode == 503) return const AssistenteIndisponivelException();
    return const InternalServerException();
  }
}