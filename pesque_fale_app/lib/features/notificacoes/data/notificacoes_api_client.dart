import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../auth/data/token_storage.dart';
import 'notificacoes_exceptions.dart';

class NotificacoesApiClient {
  NotificacoesApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _client;

  static const _timeout = Duration(seconds: 30);

  Future<Map<String, dynamic>> listar({
    int pagina = 1,
    int porPagina = 20,
  }) => _request(
    'GET',
    '/notificacoes',
    queryParams: {'pagina': '$pagina', 'porPagina': '$porPagina'},
  );

  Future<Map<String, dynamic>> contarNaoLidas() =>
      _request('GET', '/notificacoes/nao-lidas');

  Future<void> marcarTodasComoLidas() =>
      _request('PATCH', '/notificacoes/todas-lidas');

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final token = await tokenStorage.readToken();
    http.Response response;
    try {
      final uri = Uri.parse(
        '$baseUrl$path',
      ).replace(queryParameters: queryParams);
      final request = http.Request(method, uri)
        ..headers.addAll({
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        });

      final streamed = await _client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed);
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
          : jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      json = const {};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    throw _mapError(response.statusCode);
  }

  NotificacoesException _mapError(int statusCode) {
    if (statusCode == 401) return const NaoAutenticadoException();
    return const InternalServerException();
  }
}
