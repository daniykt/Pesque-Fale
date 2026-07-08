import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../auth/data/token_storage.dart';
import '../domain/usuario_resumo.dart';
import 'pontos_exceptions.dart';

class UsuariosBuscaApiClient {
  UsuariosBuscaApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _client;

  static const _timeout = Duration(seconds: 30);

  Future<List<UsuarioResumo>> buscar(String texto) async {
    final token = await tokenStorage.readToken();
    http.Response response;
    try {
      final uri = Uri.parse(
        '$baseUrl/usuarios',
      ).replace(queryParameters: {'busca': texto, 'porPagina': '20'});
      final request = http.Request('GET', uri)
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
      final data = (json['data'] as List<dynamic>?) ?? const [];
      return data
          .map((e) => UsuarioResumo.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw const InternalServerException();
  }
}
