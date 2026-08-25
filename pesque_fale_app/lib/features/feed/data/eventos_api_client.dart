import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'publicacoes_exceptions.dart';

class EventosApiClient {
  EventosApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static const _timeout = Duration(seconds: 30);

  Future<Map<String, dynamic>> listar({
    required bool futuros,
    required int porPagina,
  }) async {
    http.Response response;
    try {
      final uri = Uri.parse('$baseUrl/eventos').replace(
        queryParameters: {
          if (futuros) 'futuros': 'true',
          'porPagina': '$porPagina',
        },
      );
      final request = http.Request('GET', uri)
        ..headers.addAll({'Content-Type': 'application/json'});

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

    throw const InternalServerException();
  }
}
