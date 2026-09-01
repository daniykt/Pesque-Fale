import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/tour/domain/tour_status_storage.dart';
import 'package:pesque_fale_app/features/tour/providers/tour_provider.dart';

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

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) async => throw UnimplementedError();

  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async => throw UnimplementedError();

  @override
  Future<void> logout() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TourStatusStorage storage;

  TourProvider criarProvider() => TourProvider(
    storage: storage,
    authProvider: AuthProvider(repository: _FakeAuthRepository()),
  );

  setUp(() {
    _FakeFlutterSecureStorageChannel();
    storage = TourStatusStorage(storage: const FlutterSecureStorage());
  });

  test(
    'usuario novo: onboarding dispara o tour, percorre os 7 passos, '
    'conclui e marca como visto',
    () async {
      final tourProvider = criarProvider();

      await tourProvider.iniciarSePendente('user-1');
      expect(tourProvider.passoAtualIndex, 0);
      expect(await storage.jaViu('user-1'), isFalse);

      for (var i = 0; i < TourProvider.roteiro.length - 1; i++) {
        tourProvider.avancar();
      }
      expect(tourProvider.passoAtualIndex, TourProvider.roteiro.length - 1);

      tourProvider.avancar();
      await Future<void>.delayed(Duration.zero);

      expect(tourProvider.passoAtualIndex, isNull);
      expect(await storage.jaViu('user-1'), isTrue);
    },
  );

  test(
    'usuario que reabre o app apos concluir o tour nao o ve novamente',
    () async {
      final primeiraSessao = criarProvider();
      await primeiraSessao.iniciarSePendente('user-1');
      for (var i = 0; i < TourProvider.roteiro.length; i++) {
        primeiraSessao.avancar();
      }
      await Future<void>.delayed(Duration.zero);
      expect(await storage.jaViu('user-1'), isTrue);

      // Simula reabrir o app: nova instancia do provider, mesmo storage.
      final segundaSessao = criarProvider();
      await segundaSessao.iniciarSePendente('user-1');

      expect(segundaSessao.passoAtualIndex, isNull);
    },
  );

  test(
    'iniciarManual reabre o tour mesmo apos o usuario ja te-lo visto',
    () async {
      await storage.marcarComoVisto('user-1');
      final tourProvider = criarProvider();

      await tourProvider.iniciarSePendente('user-1');
      expect(tourProvider.passoAtualIndex, isNull);

      tourProvider.iniciarManual();
      expect(tourProvider.passoAtualIndex, 0);
    },
  );
}
