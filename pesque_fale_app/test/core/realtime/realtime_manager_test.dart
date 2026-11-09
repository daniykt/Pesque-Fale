import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:pesque_fale_app/core/realtime/realtime_manager.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';

class _FakeSocket extends Fake implements io.Socket {
  _FakeSocket(this.token);

  final String token;
  final Map<String, List<dynamic Function(dynamic)>> handlers = {};
  final List<List<dynamic>> emitidos = [];
  int conectarChamado = 0;
  bool disposeChamado = false;

  @override
  dynamic Function() on(String event, dynamic Function(dynamic) handler) {
    handlers.putIfAbsent(event, () => []).add(handler);
    return () => off(event, handler);
  }

  @override
  void off(String event, [dynamic Function(dynamic)? handler]) {
    handler == null ? handlers.remove(event) : handlers[event]?.remove(handler);
  }

  @override
  void emit(String event, [dynamic data]) {
    emitidos.add([event, ?data]);
  }

  @override
  io.Socket connect() {
    conectarChamado++;
    return this;
  }

  @override
  void dispose() {
    disposeChamado = true;
    handlers.clear();
  }

  void simular(String evento, [dynamic dados]) {
    for (final h in List.of(handlers[evento] ?? const [])) {
      h(dados);
    }
  }
}

class _FakeAuthRepository implements AuthRepository {
  String token = 'token-1';

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
  }) async => AuthResult(
    accessToken: token,
    usuario: const Usuario(
      id: '1',
      nome: 'Pescador',
      email: 'pescador@teste.com',
      onboardingConcluido: true,
    ),
  );

  @override
  Future<void> logout() async {}
}

void main() {
  late List<_FakeSocket> sockets;
  late RealtimeManager manager;
  late _FakeAuthRepository repo;
  late AuthProvider auth;

  _FakeSocket ultimo() => sockets.last;

  Future<void> logar() async {
    await auth.login(email: 'pescador@teste.com', senha: '123456');
    manager.reagirAuth(auth);
  }

  setUp(() {
    sockets = [];
    manager = RealtimeManager(
      criarSocket: (token) {
        final s = _FakeSocket(token);
        sockets.add(s);
        return s;
      },
    );
    repo = _FakeAuthRepository();
    auth = AuthProvider(repository: repo);
  });

  group('RealtimeManager.reagirAuth', () {
    test('sem sessão não cria socket', () {
      manager.reagirAuth(auth);

      expect(sockets, isEmpty);
      expect(manager.conectado, isFalse);
    });

    test('login cria um socket com o token da sessão e conecta', () async {
      await logar();

      expect(sockets, hasLength(1));
      expect(ultimo().token, 'token-1');
      expect(ultimo().conectarChamado, 1);

      ultimo().simular('connect');
      expect(manager.conectado, isTrue);
    });

    test('mesmo token de novo é no-op (não abre segunda conexão)', () async {
      await logar();
      manager.reagirAuth(auth);
      manager.reagirAuth(auth);

      expect(sockets, hasLength(1));
      expect(ultimo().conectarChamado, 1);
    });

    test('logout descarta o socket e zera o estado', () async {
      await logar();
      ultimo().simular('connect');

      await auth.signOut();
      manager.reagirAuth(auth);

      expect(sockets.single.disposeChamado, isTrue);
      expect(manager.conectado, isFalse);
    });

    test('troca de conta (token novo) descarta o socket antigo', () async {
      await logar();
      await auth.signOut();
      repo.token = 'token-2';
      await logar();

      expect(sockets, hasLength(2));
      expect(sockets.first.disposeChamado, isTrue);
      expect(sockets.last.token, 'token-2');
    });
  });

  group('RealtimeManager.subscribe/unsubscribe', () {
    test('assinatura feita antes do login é aplicada ao socket novo', () async {
      final recebidos = <dynamic>[];
      manager.subscribe('nova_notificacao', recebidos.add);

      await logar();
      ultimo().simular('nova_notificacao', {'id': 1});

      expect(recebidos, [
        {'id': 1},
      ]);
    });

    test('assinatura sobrevive a logout + novo login', () async {
      final recebidos = <dynamic>[];
      manager.subscribe('nova_notificacao', recebidos.add);

      await logar();
      await auth.signOut();
      manager.reagirAuth(auth);
      repo.token = 'token-2';
      await logar();
      ultimo().simular('nova_notificacao', 'x');

      expect(recebidos, ['x']);
    });

    test('unsubscribe remove só o callback informado', () async {
      final a = <dynamic>[];
      final b = <dynamic>[];
      void cbA(dynamic d) => a.add(d);
      void cbB(dynamic d) => b.add(d);
      manager.subscribe('evento', cbA);
      manager.subscribe('evento', cbB);
      await logar();

      manager.unsubscribe('evento', cbA);
      ultimo().simular('evento', 1);

      expect(a, isEmpty);
      expect(b, [1]);
    });
  });

  group('RealtimeManager.onReconnect', () {
    test('não dispara na primeira conexão, dispara a cada reconexão', () async {
      var chamadas = 0;
      manager.onReconnect(() => chamadas++);
      await logar();

      ultimo().simular('connect');
      expect(chamadas, 0);

      ultimo().simular('disconnect');
      expect(manager.conectado, isFalse);
      ultimo().simular('connect');
      expect(chamadas, 1);
      expect(manager.conectado, isTrue);

      ultimo().simular('disconnect');
      ultimo().simular('connect');
      expect(chamadas, 2);
    });

    test('primeira conexão de uma sessão nova não conta como reconexão', () async {
      var chamadas = 0;
      manager.onReconnect(() => chamadas++);
      await logar();
      ultimo().simular('connect');

      await auth.signOut();
      manager.reagirAuth(auth);
      repo.token = 'token-2';
      await logar();
      ultimo().simular('connect');

      expect(chamadas, 0);
    });
  });

  group('RealtimeManager.removerOnReconnect', () {
    void cairEVoltar() {
      ultimo().simular('disconnect');
      ultimo().simular('connect');
    }

    test('callback removido não dispara mais; os outros seguem', () async {
      var removido = 0;
      var mantido = 0;
      void cbRemovido() => removido++;
      manager.onReconnect(cbRemovido);
      manager.onReconnect(() => mantido++);
      await logar();
      ultimo().simular('connect');

      manager.removerOnReconnect(cbRemovido);
      cairEVoltar();

      expect(removido, 0);
      expect(mantido, 1);
    });

    test('callback não registrado é no-op', () {
      expect(() => manager.removerOnReconnect(() {}), returnsNormally);
    });

    test('remover duas vezes o mesmo callback é seguro', () async {
      var chamadas = 0;
      void cb() => chamadas++;
      manager.onReconnect(cb);

      manager.removerOnReconnect(cb);
      expect(() => manager.removerOnReconnect(cb), returnsNormally);

      await logar();
      ultimo().simular('connect');
      cairEVoltar();
      expect(chamadas, 0);
    });

    test('assina → remove → login → remove de novo não quebra', () async {
      var chamadas = 0;
      void cb() => chamadas++;
      manager.onReconnect(cb);
      manager.removerOnReconnect(cb);

      await logar();
      ultimo().simular('connect');
      expect(() => manager.removerOnReconnect(cb), returnsNormally);
      cairEVoltar();

      expect(chamadas, 0);
      expect(manager.conectado, isTrue);
    });
  });

  group('RealtimeManager.emit', () {
    test('sem sessão é no-op e não lança', () {
      expect(() => manager.emit('marcar_visto'), returnsNormally);
      expect(sockets, isEmpty);
    });

    test('socket criado mas ainda não conectado descarta (sem fila)', () async {
      await logar();

      manager.emit('entrar_chat', {'outroId': 'x'});
      ultimo().simular('connect');

      expect(ultimo().emitidos, isEmpty);
    });

    test('conectado repassa evento e payload pro socket', () async {
      await logar();
      ultimo().simular('connect');

      manager.emit('entrar_chat', {'outroId': 'x'});

      expect(ultimo().emitidos, [
        [
          'entrar_chat',
          {'outroId': 'x'},
        ],
      ]);
    });

    test('sem payload emite só o evento', () async {
      await logar();
      ultimo().simular('connect');

      manager.emit('marcar_visto');

      expect(ultimo().emitidos, [
        ['marcar_visto'],
      ]);
    });

    test('depois de cair, volta a descartar', () async {
      await logar();
      ultimo().simular('connect');
      ultimo().simular('disconnect');

      manager.emit('marcar_visto');

      expect(ultimo().emitidos, isEmpty);
    });
  });

  test('dispose descarta o socket aberto', () async {
    await logar();
    manager.dispose();

    expect(sockets.single.disposeChamado, isTrue);
  });

  testWidgets(
    'plugado via ChangeNotifierProxyProvider(lazy: false), conecta no login '
    'e desconecta no logout sem ninguém ler o manager',
    (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProxyProvider<AuthProvider, RealtimeManager>(
              lazy: false,
              create: (_) => manager,
              update: (context, auth, previous) => previous!..reagirAuth(auth),
            ),
          ],
          child: const SizedBox(),
        ),
      );
      expect(sockets, isEmpty);

      await tester.runAsync(
        () => auth.login(email: 'pescador@teste.com', senha: '123456'),
      );
      await tester.pump();
      expect(sockets, hasLength(1));

      ultimo().simular('connect');
      await tester.runAsync(auth.signOut);
      await tester.pump();
      expect(sockets.single.disposeChamado, isTrue);
      expect(manager.conectado, isFalse);
    },
  );
}
