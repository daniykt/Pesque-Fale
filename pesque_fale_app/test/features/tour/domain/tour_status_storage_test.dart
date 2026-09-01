import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/tour/domain/tour_status_storage.dart';

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

  late TourStatusStorage storage;

  setUp(() {
    _FakeFlutterSecureStorageChannel();
    storage = TourStatusStorage(storage: const FlutterSecureStorage());
  });

  test('jaViu retorna false quando chave nao existe', () async {
    expect(await storage.jaViu('user-1'), isFalse);
  });

  test(
    "marcarComoVisto persiste 'true' na chave certa e jaViu retorna true depois",
    () async {
      await storage.marcarComoVisto('user-1');
      expect(await storage.jaViu('user-1'), isTrue);
    },
  );

  test('limpar remove a chave e jaViu volta a retornar false', () async {
    await storage.marcarComoVisto('user-1');
    expect(await storage.jaViu('user-1'), isTrue);

    await storage.limpar('user-1');
    expect(await storage.jaViu('user-1'), isFalse);
  });

  test('chaves de usuarios diferentes nao interferem entre si', () async {
    await storage.marcarComoVisto('user-1');

    expect(await storage.jaViu('user-1'), isTrue);
    expect(await storage.jaViu('user-2'), isFalse);
  });
}
