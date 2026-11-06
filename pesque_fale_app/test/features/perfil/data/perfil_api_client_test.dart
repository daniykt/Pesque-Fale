import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pesque_fale_app/features/auth/data/token_storage.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_api_client.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_exceptions.dart';

class _FakeTokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => 'token-teste';
}

const _baseUrl = 'http://test.local/v1';

PerfilApiClient _clientRespondendo(int status, Map<String, dynamic> body) {
  return PerfilApiClient(
    baseUrl: _baseUrl,
    tokenStorage: _FakeTokenStorage(),
    client: MockClient(
      (_) async => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    ),
  );
}

void main() {
  group('PerfilApiClient.editarPerfil — erros de username', () {
    test(
      '409 USERNAME_JA_CADASTRADO vira UsernameJaCadastradoException',
      () async {
        final api = _clientRespondendo(409, {
          'error': 'USERNAME_JA_CADASTRADO',
          'message': 'Este username já está em uso.',
        });

        await expectLater(
          api.editarPerfil({'username': 'ocupado'}),
          throwsA(isA<UsernameJaCadastradoException>()),
        );
      },
    );

    test('400 VALIDATION_ERROR só com username vira PerfilValidationException '
        'com a mensagem da API', () async {
      const mensagem =
          'Username deve ter 3-20 caracteres: letras, números, _ ou .';
      final api = _clientRespondendo(400, {
        'error': 'VALIDATION_ERROR',
        'message': 'Verifique os campos e tente novamente.',
        'details': [
          {'campo': 'username', 'mensagem': mensagem},
        ],
      });

      await expectLater(
        api.editarPerfil({'username': 'a!'}),
        throwsA(
          isA<PerfilValidationException>().having(
            (e) => e.fieldErrors,
            'fieldErrors',
            {'username': mensagem},
          ),
        ),
      );
    });
  });
}
