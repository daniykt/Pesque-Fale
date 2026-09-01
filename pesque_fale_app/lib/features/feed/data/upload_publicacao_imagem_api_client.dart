import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../auth/data/token_storage.dart';
import 'upload_publicacao_imagem_exceptions.dart';

class UploadPublicacaoImagemApiClient {
  UploadPublicacaoImagemApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _client;

  static const _timeout = Duration(seconds: 30);

  Future<Map<String, dynamic>> upload(File arquivo) async {
    final token = await tokenStorage.readToken();
    http.Response response;
    try {
      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse('$baseUrl/publicacoes/imagens'),
            )
            ..headers.addAll({
              if (token != null) 'Authorization': 'Bearer $token',
            })
            ..files.add(
              await http.MultipartFile.fromPath('imagem', arquivo.path),
            );

      final streamed = await _client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const UploadPublicacaoImagemException(
        'Sem conexão com o servidor.',
      );
    } on SocketException {
      throw const UploadPublicacaoImagemException(
        'Sem conexão com o servidor.',
      );
    } on http.ClientException {
      throw const UploadPublicacaoImagemException(
        'Sem conexão com o servidor.',
      );
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

  Exception _mapError(int statusCode, Map<String, dynamic> json) {
    final code = json['error']?.toString();
    switch (code) {
      case 'ARQUIVO_MUITO_GRANDE':
        return const UploadArquivoMuitoGrandeException();
      case 'FORMATO_INVALIDO':
        return const UploadFormatoInvalidoException();
      default:
        if (statusCode == 413) {
          return const UploadArquivoMuitoGrandeException();
        }
        if (statusCode == 415) {
          return const UploadFormatoInvalidoException();
        }
        return const UploadPublicacaoImagemException(
          'Não foi possível enviar a imagem.',
        );
    }
  }
}
