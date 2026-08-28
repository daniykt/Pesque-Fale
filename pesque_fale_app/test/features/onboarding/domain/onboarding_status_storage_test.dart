import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/onboarding/domain/onboarding_status_storage.dart';

/// Fake do canal de plataforma do flutter_secure_storage, com os dados
/// mantidos em um Map em memória (sem depender de nenhum plugin nativo).
class _FakeFlutterSecureStorageChannel {
  _FakeFlutterSecureStorageChannel() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, _handle);
  }

  static const _channel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final Map<String, String> _dados = {};

  Future<dynamic> _handle(MethodCall call) async {
    final args = (call.arguments as Map).cast<String, dynamic>();
    switch (call.method) {
      case 'read':
        return _dados[args['key'] as String];
      case 'write':
        _dados[args['key'] as String] = args['value'] as String;
        return null;
      case 'delete':
        _dados.remove(args['key'] as String);
        return null;
      case 'containsKey':
        return _dados.containsKey(args['key'] as String);
      case 'readAll':
        return _dados;
      case 'deleteAll':
        _dados.clear();
        return null;
    }
    throw UnimplementedError(call.method);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OnboardingStatusStorage storage;

  setUp(() {
    _FakeFlutterSecureStorageChannel();
    storage = OnboardingStatusStorage(storage: const FlutterSecureStorage());
  });

  test('isConcluido retorna false quando chave nao existe', () async {
    expect(await storage.isConcluido('user-1'), isFalse);
  });

  test(
    "marcarConcluido persiste 'true' na chave certa e isConcluido retorna true depois",
    () async {
      await storage.marcarConcluido('user-1');
      expect(await storage.isConcluido('user-1'), isTrue);
    },
  );

  test('limpar remove a chave e isConcluido volta a retornar false', () async {
    await storage.marcarConcluido('user-1');
    expect(await storage.isConcluido('user-1'), isTrue);

    await storage.limpar('user-1');
    expect(await storage.isConcluido('user-1'), isFalse);
  });

  test('chaves de usuarios diferentes nao interferem entre si', () async {
    await storage.marcarConcluido('user-1');

    expect(await storage.isConcluido('user-1'), isTrue);
    expect(await storage.isConcluido('user-2'), isFalse);
  });
}
