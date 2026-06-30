import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/auth_result.dart';
import 'auth_exceptions.dart';

class AuthApiClient {
  AuthApiClient({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static const _timeout = Duration(seconds: 10);

  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) {
    return _post('/auth/cadastro', {
      'nome': nome,
      'email': email,
      'senha': senha,
      'confirmarSenha': confirmarSenha,
    });
  }

  Future<AuthResult> login({required String email, required String senha}) {
    return _post('/auth/login', {'email': email, 'senha': senha});
  }

  Future<AuthResult> _post(String path, Map<String, dynamic> body) async {
    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const NetworkException();
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }

    final Map<String, dynamic> json = response.body.isEmpty
        ? const {}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AuthResult.fromJson((json['data'] as Map<String, dynamic>?) ?? const {});
    }

    throw _mapError(response.statusCode, json);
  }

  AuthException _mapError(int statusCode, Map<String, dynamic> json) {
    final code = json['error']?.toString();

    switch (code) {
      case 'VALIDATION_ERROR':
        final details = (json['details'] as List<dynamic>?) ?? const [];
        return ValidationException(
          details.map((e) => FieldError.fromJson(e as Map<String, dynamic>)).toList(),
        );
      case 'EMAIL_JA_CADASTRADO':
        return const EmailJaCadastradoException();
      case 'CREDENCIAIS_INVALIDAS':
        return const CredenciaisInvalidasException();
      default:
        return const InternalServerException();
    }
  }
}
