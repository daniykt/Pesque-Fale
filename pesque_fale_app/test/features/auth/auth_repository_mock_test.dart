import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/auth/data/auth_exceptions.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository_mock.dart';
import 'package:pesque_fale_app/features/auth/data/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final storedValues = <String, String?>{};

  setUp(() {
    storedValues.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'write':
              final args = call.arguments as Map;
              storedValues[args['key'] as String] = args['value'] as String?;
              return null;
            case 'read':
              final args = call.arguments as Map;
              return storedValues[args['key'] as String];
            case 'delete':
              final args = call.arguments as Map;
              storedValues.remove(args['key'] as String);
              return null;
            default:
              return null;
          }
        });
  });

  late AuthRepositoryMock repository;

  setUp(() {
    repository = AuthRepositoryMock(tokenStorage: TokenStorage());
  });

  group('AuthRepositoryMock.cadastrar', () {
    test('retorna sucesso para email novo', () async {
      final result = await repository.cadastrar(
        nome: 'Pescador',
        email: 'novo@teste.com',
        senha: '123456',
        confirmarSenha: '123456',
      );

      expect(result.accessToken, isNotEmpty);
      expect(result.usuario.email, 'novo@teste.com');
    });

    test('lanca EmailJaCadastradoException para email existente', () async {
      expect(
        () => repository.cadastrar(
          nome: 'Pescador',
          email: 'existente@teste.com',
          senha: '123456',
          confirmarSenha: '123456',
        ),
        throwsA(isA<EmailJaCadastradoException>()),
      );
    });

    test('lanca InternalServerException para email de erro', () async {
      expect(
        () => repository.cadastrar(
          nome: 'Pescador',
          email: 'erro@teste.com',
          senha: '123456',
          confirmarSenha: '123456',
        ),
        throwsA(isA<InternalServerException>()),
      );
    });
  });
}
