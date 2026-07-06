import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../auth/data/token_storage.dart';
import '../../auth/domain/usuario.dart';
import '../domain/publicacao.dart';
import 'perfil_exceptions.dart';

class PerfilApiClient {
  PerfilApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _client;

  static const _timeout = Duration(seconds: 10);

  Future<Usuario> buscarPerfil(String id) async {
    final json = await _request('GET', '/usuarios/$id');
    return Usuario.fromJson(json);
  }

  Future<void> seguir(String id) async {
    await _request('POST', '/usuarios/$id/seguir');
  }

  Future<void> deixarDeSeguir(String id) async {
    await _request('DELETE', '/usuarios/$id/seguir');
  }

  /// Endpoint ainda não implementado no backend — degrada para lista vazia
  /// via [RecursoNaoDisponivelException] (ver issue de continuação).
  Future<List<Publicacao>> buscarPublicacoes(String id) async {
    try {
      final json = await _request('GET', '/usuarios/$id/publicacoes');
      final lista = (json['publicacoes'] as List<dynamic>?) ?? const [];
      return lista
          .map((e) => Publicacao.fromJson(e as Map<String, dynamic>))
          .toList();
    } on RecursoNaoDisponivelException {
      return const [];
    }
  }

  Future<String> atualizarFoto(File arquivo) =>
      _upload('/usuarios/me/foto', arquivo);

  Future<String> atualizarBanner(File arquivo) =>
      _upload('/usuarios/me/banner', arquivo);

  Future<Usuario> editarPerfil(Map<String, dynamic> campos) async {
    final json = await _request('PATCH', '/usuarios/me', body: campos);
    return Usuario.fromJson(json);
  }

  Future<bool> verificarUsername(String username) async {
    final json = await _request('GET', '/usuarios/username/$username');
    return json['disponivel'] as bool? ?? false;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await tokenStorage.readToken();
    http.Response response;
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'))
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

    return _handleResponse(response);
  }

  Future<String> _upload(String path, File arquivo) async {
    final token = await tokenStorage.readToken();
    http.Response response;
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
        ..headers.addAll({if (token != null) 'Authorization': 'Bearer $token'})
        ..files.add(await http.MultipartFile.fromPath('arquivo', arquivo.path));

      final streamed = await _client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const NetworkException();
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }

    final json = _handleResponse(response);
    return json['url']?.toString() ?? '';
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> json;
    try {
      json = response.body.isEmpty
          ? const {}
          : jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      // Endpoint ainda não existe no backend e devolveu HTML (404 padrão do
      // Express) em vez do envelope JSON esperado.
      json = const {};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (json['data'] as Map<String, dynamic>?) ?? json;
    }

    throw _mapError(response.statusCode, json);
  }

  PerfilException _mapError(int statusCode, Map<String, dynamic> json) {
    final code = json['error']?.toString();

    switch (code) {
      case 'USUARIO_NAO_ENCONTRADO':
        return const PerfilNaoEncontradoException();
      case 'VALIDATION_ERROR':
        final details = (json['details'] as List<dynamic>?) ?? const [];
        final fieldErrors = <String, String>{};
        for (final d in details) {
          final m = d as Map<String, dynamic>;
          fieldErrors[m['campo']?.toString() ?? 'geral'] =
              m['mensagem']?.toString() ?? '';
        }
        if (fieldErrors.length == 1 && fieldErrors.containsKey('username')) {
          return const UsernameJaCadastradoException();
        }
        if (fieldErrors.isNotEmpty) return PerfilValidationException(fieldErrors);
        return const FormatoInvalidoException();
      default:
        if (statusCode == 404) return const RecursoNaoDisponivelException();
        return const InternalServerException();
    }
  }
}
