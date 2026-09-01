import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
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
  late AuthProvider authProvider;
  late TourProvider tourProvider;

  Usuario usuario(String id) => Usuario(
    id: id,
    nome: 'Ana',
    email: 'ana@teste.com',
    onboardingConcluido: true,
  );

  setUp(() {
    _FakeFlutterSecureStorageChannel();
    storage = TourStatusStorage(storage: const FlutterSecureStorage());
    authProvider = AuthProvider(repository: _FakeAuthRepository());
    tourProvider = TourProvider(storage: storage, authProvider: authProvider);
  });

  test('roteiro tem 7 passos', () {
    expect(TourProvider.roteiro, hasLength(7));
  });

  test('passoAtual e passoAtualIndex sao nulos antes de iniciar', () {
    expect(tourProvider.passoAtualIndex, isNull);
    expect(tourProvider.passoAtual, isNull);
  });

  group('iniciarSePendente', () {
    test('inicia no passo 0 quando o usuario ainda nao viu o tour', () async {
      await tourProvider.iniciarSePendente('user-1');

      expect(tourProvider.passoAtualIndex, 0);
      expect(tourProvider.passoAtual, TourProvider.roteiro[0]);
    });

    test('nao inicia quando o usuario ja viu o tour', () async {
      await storage.marcarComoVisto('user-1');

      await tourProvider.iniciarSePendente('user-1');

      expect(tourProvider.passoAtualIndex, isNull);
    });
  });

  test('iniciarManual sempre inicia, mesmo se ja visto', () async {
    await storage.marcarComoVisto('user-1');
    authProvider.atualizarUsuario(usuario('user-1'));

    tourProvider.iniciarManual();

    expect(tourProvider.passoAtualIndex, 0);
  });

  test('avancar percorre os passos ate o ultimo e depois conclui', () async {
    await tourProvider.iniciarSePendente('user-1');

    for (var i = 1; i < TourProvider.roteiro.length; i++) {
      tourProvider.avancar();
      expect(tourProvider.passoAtualIndex, i);
    }

    tourProvider.avancar();
    await Future<void>.delayed(Duration.zero);

    expect(tourProvider.passoAtualIndex, isNull);
    expect(await storage.jaViu('user-1'), isTrue);
  });

  test('voltar retrocede um passo e nao passa do passo 0', () async {
    await tourProvider.iniciarSePendente('user-1');
    tourProvider.avancar();
    tourProvider.avancar();

    tourProvider.voltar();
    expect(tourProvider.passoAtualIndex, 1);

    tourProvider.voltar();
    tourProvider.voltar();
    expect(tourProvider.passoAtualIndex, 0);
  });

  test('pular no meio do tour fecha e marca como visto', () async {
    await tourProvider.iniciarSePendente('user-1');
    tourProvider.avancar();

    await tourProvider.pular();

    expect(tourProvider.passoAtualIndex, isNull);
    expect(await storage.jaViu('user-1'), isTrue);
  });

  test('concluir no ultimo passo marca como visto', () async {
    await tourProvider.iniciarSePendente('user-1');
    for (var i = 1; i < TourProvider.roteiro.length; i++) {
      tourProvider.avancar();
    }

    await tourProvider.concluir();

    expect(tourProvider.passoAtualIndex, isNull);
    expect(await storage.jaViu('user-1'), isTrue);
  });

  test(
    'pular sem usuario ativo nao lanca erro e apenas encerra o tour',
    () async {
      tourProvider.iniciarManual();

      await tourProvider.pular();

      expect(tourProvider.passoAtualIndex, isNull);
    },
  );
}
