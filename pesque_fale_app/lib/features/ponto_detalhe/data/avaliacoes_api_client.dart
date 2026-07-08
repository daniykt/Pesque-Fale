import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../auth/data/token_storage.dart';
import 'avaliacoes_exceptions.dart';

class AvaliacoesApiClient {
  AvaliacoesApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _client;

  static const _timeout = Duration(seconds: 30);

  Future<Map<String, dynamic>> listar(
    String pontoId, {
    int pagina = 1,
    int porPagina = 20,
  }) {
    return _request(
      'GET',
      '/pontos/$pontoId/avaliacoes',
      queryParams: {'pagina': '$pagina', 'porPagina': '$porPagina'},
      comMeta: true,
    );
  }

  Future<Map<String, dynamic>> minhaAvaliacao(String pontoId) {
    return _request('GET', '/pontos/$pontoId/avaliacoes/minha');
  }

  Future<Map<String, dynamic>> criar(
    String pontoId,
    Map<String, dynamic> body,
  ) {
    return _request('POST', '/pontos/$pontoId/avaliacoes', body: body);
  }

  Future<Map<String, dynamic>> editar(
    String pontoId,
    Map<String, dynamic> body,
  ) {
    return _request(
      'PATCH',
      '/pontos/$pontoId/avaliacoes/minha',
      body: body,
    );
  }

  Future<void> deletar(String pontoId) {
    return _request('DELETE', '/pontos/$pontoId/avaliacoes/minha');
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool comMeta = false,
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
      if (comMeta) return json;
      return (json['data'] as Map<String, dynamic>?) ?? json;
    }

    throw _mapError(response.statusCode, json);
  }

  AvaliacoesException _mapError(int statusCode, Map<String, dynamic> json) {
    final code = json['error']?.toString();

    switch (code) {
      case 'TOKEN_INVALIDO':
        return const NaoAutenticadoException();
      case 'AVALIACAO_JA_EXISTE':
        return const JaAvaliouException();
      case 'AVALIACAO_NAO_ENCONTRADA':
        return const AvaliacaoNaoEncontradaException();
      case 'PONTO_NAO_ENCONTRADO':
        return const PontoNaoEncontradoException();
      case 'VALIDATION_ERROR':
        final details = (json['details'] as List<dynamic>?) ?? const [];
        final mensagem = details.isNotEmpty
            ? (details.first as Map<String, dynamic>)['mensagem']?.toString()
            : json['message']?.toString();
        return AvaliacoesValidationException(
          mensagem ?? 'Verifique os campos e tente novamente.',
        );
      default:
        if (statusCode == 401) return const NaoAutenticadoException();
        if (statusCode == 404) return const AvaliacaoNaoEncontradaException();
        return const InternalServerException();
    }
  }
}
