import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'clima_exceptions.dart';

class ClimaApiClient {
  ClimaApiClient({
    this.baseUrl = 'https://api.open-meteo.com/v1',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static const _timeout = Duration(seconds: 15);

  Future<Map<String, dynamic>> buscarAtual({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$baseUrl/forecast').replace(
      queryParameters: {
        'latitude': latitude.toStringAsFixed(2),
        'longitude': longitude.toStringAsFixed(2),
        'current':
            'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code',
        'wind_speed_unit': 'kmh',
        'timezone': 'auto',
      },
    );

    http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw const ClimaRedeException();
    } on http.ClientException {
      throw const ClimaRedeException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ClimaServicoException();
    }

    try {
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) throw const FormatException();
      return json;
    } on FormatException {
      throw const ClimaServicoException();
    }
  }
}
