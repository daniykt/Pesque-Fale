import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../auth/data/token_storage.dart';
import 'eventos_exceptions.dart';

class EventosApiClient {
  EventosApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _client;

  static const _timeout = Duration(seconds: 30);

  Future<Map<String, dynamic>> listar({
    required bool futuros,
    required int porPagina,
  }) {
    return _request(
      'GET',
      '/eventos',
      queryParams: {if (futuros) 'futuros': 'true', 'porPagina': '$porPagina'},
    );
  }

  Future<Map<String, dynamic>> buscarPorId(String id) =>
      _request('GET', '/eventos/${Uri.encodeComponent(id)}');

  Future<Map<String, dynamic>> criar(Map<String, dynamic> body) =>
      _request('POST', '/eventos', body: body);

  Future<Map<String, dynamic>> editar(String id, Map<String, dynamic> body) =>
      _request('PATCH', '/eventos/${Uri.encodeComponent(id)}', body: body);

  Future<void> excluir(String id) =>
      _request('DELETE', '/eventos/${Uri.encodeComponent(id)}');

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
      throw const EventosRedeException();
    } on SocketException {
      throw const EventosRedeException();
    } on http.ClientException {
      throw const EventosRedeException();
    }

    Map<String, dynamic> json;
    try {
      final decodificado = response.body.isEmpty
          ? null
          : jsonDecode(response.body);
      json = decodificado is Map<String, dynamic> ? decodificado : const {};
    } on FormatException {
      json = const {};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    throw _mapError(response.statusCode, json);
  }

  EventosException _mapError(int statusCode, Map<String, dynamic> json) {
    switch (json['error']?.toString()) {
      case 'EVENTO_NAO_ENCONTRADO':
        return const EventoNaoEncontradoException();
      case 'FORBIDDEN':
        return const EventoSemPermissaoException();
      case 'VALIDATION_ERROR':
        return EventoValidacaoException(_errosPorCampo(json['details']));
    }
    if (statusCode == 401) return const EventoNaoAutenticadoException();
    if (statusCode == 404) return const EventoNaoEncontradoException();
    return const EventosServidorException();
  }

  Map<String, String> _errosPorCampo(Object? details) {
    final erros = <String, String>{};
    if (details is! List) return erros;
    for (final item in details) {
      if (item is! Map) continue;
      final campo = item['campo']?.toString();
      final mensagem = item['mensagem']?.toString();
      if (campo == null || mensagem == null) continue;
      erros.putIfAbsent(campo, () => mensagem);
    }
    return erros;
  }
}
