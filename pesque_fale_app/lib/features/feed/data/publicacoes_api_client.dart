import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../auth/data/token_storage.dart';
import 'publicacoes_exceptions.dart';

class PublicacoesApiClient {
  PublicacoesApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _client;

  static const _timeout = Duration(seconds: 30);

  Future<Map<String, dynamic>> listar({
    required int pagina,
    required int porPagina,
    required bool seguindo,
  }) {
    return _request(
      'GET',
      '/publicacoes',
      queryParams: {
        'pagina': '$pagina',
        'porPagina': '$porPagina',
        if (seguindo) 'seguindo': 'true',
      },
    );
  }

  Future<Map<String, dynamic>> buscarPorId(String id) =>
      _request('GET', '/publicacoes/$id');

  Future<void> deletar(String id) => _request('DELETE', '/publicacoes/$id');

  Future<Map<String, dynamic>> criar(Map<String, dynamic> body) =>
      _request('POST', '/publicacoes', body: body);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
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
      if (body != null) request.body = jsonEncode(body);

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

    throw _mapError(response.statusCode, json);
  }

  PublicacoesException _mapError(int statusCode, Map<String, dynamic> json) {
    final code = json['error']?.toString();

    switch (code) {
      case 'PUBLICACAO_NAO_ENCONTRADA':
        return const PublicacaoNaoEncontradaException();
      case 'FORBIDDEN':
        return const ForbiddenException();
      default:
        if (statusCode == 401) return const NaoAutenticadoException();
        return const InternalServerException();
    }
  }
}
