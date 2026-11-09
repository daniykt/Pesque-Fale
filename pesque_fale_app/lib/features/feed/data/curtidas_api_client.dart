import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../auth/data/token_storage.dart';
import 'publicacoes_exceptions.dart';

class CurtidasApiClient {
  CurtidasApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _client;

  static const _timeout = Duration(seconds: 30);

  Future<void> curtir(String publicacaoId) =>
      _request('POST', '/publicacoes/$publicacaoId/curtir');

  Future<void> descurtir(String publicacaoId) =>
      _request('DELETE', '/publicacoes/$publicacaoId/curtir');

  Future<void> _request(String method, String path) async {
    final token = await tokenStorage.readToken();
    http.Response response;
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'))
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

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    Map<String, dynamic> json;
    try {
      json = response.body.isEmpty
          ? const {}
          : jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      json = const {};
    }

    final code = json['error']?.toString();
    if (code == 'PUBLICACAO_NAO_ENCONTRADA') {
      throw const PublicacaoNaoEncontradaException();
    }
    if (response.statusCode == 401) throw const NaoAutenticadoException();
    throw const InternalServerException();
  }
}
