import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../auth/data/token_storage.dart';
import '../../auth/domain/usuario.dart';
import '../domain/perfil_completo.dart';
import '../domain/publicacao.dart';
import 'perfil_exceptions.dart';

class UsuarioResumido {
  const UsuarioResumido({
    required this.id,
    required this.nome,
    this.username,
    this.fotoPerfil,
  });

  final String id;
  final String nome;
  final String? username;
  final String? fotoPerfil;

  factory UsuarioResumido.fromJson(Map<String, dynamic> json) {
    return UsuarioResumido(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      username: json['username'] as String?,
      fotoPerfil: json['fotoPerfil'] as String?,
    );
  }
}

class ListaPaginada<T> {
  const ListaPaginada({
    required this.itens,
    required this.total,
    required this.pagina,
    required this.porPagina,
  });

  final List<T> itens;
  final int total;
  final int pagina;
  final int porPagina;
}

class PerfilApiClient {
  PerfilApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _client;

  static const _timeout = Duration(seconds: 30);

  Future<PerfilCompleto> buscarPerfil(String id) async {
    final json = await _request('GET', '/usuarios/$id');
    final usuario = Usuario.fromJson(json);
    return PerfilCompleto(
      usuario: usuario,
      isFollowing: json['souSeguidor'] as bool? ?? false,
      seguidoPeloOutro: json['meSegue'] as bool? ?? false,
    );
  }

  Future<void> seguir(String id) async {
    await _request('POST', '/usuarios/$id/seguir');
  }

  Future<void> deixarDeSeguir(String id) async {
    await _request('DELETE', '/usuarios/$id/seguir');
  }

  Future<ListaPaginada<UsuarioResumido>> buscarSeguidores(
    String id, {
    int pagina = 1,
    int porPagina = 20,
  }) async {
    final json = await _requestPaginado(
      'GET',
      '/usuarios/$id/seguidores',
      queryParams: {'pagina': '$pagina', 'porPagina': '$porPagina'},
    );
    final itens = (json['data'] as List<dynamic>? ?? [])
        .map((e) => UsuarioResumido.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return ListaPaginada(
      itens: itens,
      total: meta['total'] as int? ?? 0,
      pagina: meta['pagina'] as int? ?? pagina,
      porPagina: meta['porPagina'] as int? ?? porPagina,
    );
  }

  Future<ListaPaginada<UsuarioResumido>> buscarSeguindo(
    String id, {
    int pagina = 1,
    int porPagina = 20,
  }) async {
    final json = await _requestPaginado(
      'GET',
      '/usuarios/$id/seguindo',
      queryParams: {'pagina': '$pagina', 'porPagina': '$porPagina'},
    );
    final itens = (json['data'] as List<dynamic>? ?? [])
        .map((e) => UsuarioResumido.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return ListaPaginada(
      itens: itens,
      total: meta['total'] as int? ?? 0,
      pagina: meta['pagina'] as int? ?? pagina,
      porPagina: meta['porPagina'] as int? ?? porPagina,
    );
  }

  Future<ListaPaginada<Publicacao>> buscarPublicacoes(
    String id, {
    int pagina = 1,
    int porPagina = 12,
  }) async {
    final json = await _requestPaginado(
      'GET',
      '/usuarios/$id/publicacoes',
      queryParams: {'pagina': '$pagina', 'porPagina': '$porPagina'},
    );
    final itens = (json['data'] as List<dynamic>? ?? [])
        .map((e) => Publicacao.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return ListaPaginada(
      itens: itens,
      total: meta['total'] as int? ?? 0,
      pagina: meta['pagina'] as int? ?? pagina,
      porPagina: meta['porPagina'] as int? ?? porPagina,
    );
  }

  Future<String> atualizarFoto(File arquivo) =>
      _upload('/usuarios/me/foto', arquivo, campo: 'foto');

  Future<String> atualizarBanner(File arquivo) =>
      _upload('/usuarios/me/banner', arquivo, campo: 'banner');

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

  Future<Map<String, dynamic>> _requestPaginado(
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
    throw _mapError(response.statusCode, json);
  }

  Future<String> _upload(
    String path,
    File arquivo, {
    required String campo,
  }) async {
    final token = await tokenStorage.readToken();
    http.Response response;
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
        ..headers.addAll({if (token != null) 'Authorization': 'Bearer $token'})
        ..files.add(await http.MultipartFile.fromPath(campo, arquivo.path));

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
    return json['fotoPerfil']?.toString() ?? json['banner']?.toString() ?? '';
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> json;
    try {
      json = response.body.isEmpty
          ? const {}
          : jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
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
      case 'ARQUIVO_MUITO_GRANDE':
        return const FotoMuitoGrandeException();
      case 'FORMATO_INVALIDO':
        return const FormatoInvalidoException();
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
        if (fieldErrors.isNotEmpty) {
          return PerfilValidationException(fieldErrors);
        }
        return const FormatoInvalidoException();
      default:
        if (statusCode == 404) return const RecursoNaoDisponivelException();
        return const InternalServerException();
    }
  }
}