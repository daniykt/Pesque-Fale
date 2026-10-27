import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/notificacoes/data/notificacoes_repository.dart';
import 'package:pesque_fale_app/features/notificacoes/domain/notificacao.dart';
import 'package:pesque_fale_app/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository_mock.dart';

import '../../chat/support/fake_realtime_manager.dart';

Notificacao _notificacao(String id, {bool lida = true}) => Notificacao(
  id: id,
  para: 'me',
  tipo: TipoNotificacao.sistema,
  texto: 'Notificação $id',
  lida: lida,
  criadoEm: DateTime(2026, 9, 1),
);

/// Payload de `nova_notificacao` no shape do `_format` do backend.
Map<String, dynamic> _payload({
  String id = 'nova-1',
  String tipo = 'curtida',
  bool lida = false,
}) => {
  'id': id,
  'para': 'me',
  'deId': 'user-a',
  'de': 'Fulano',
  'deUsername': 'fulano',
  'deFoto': null,
  'jaSigoDe': false,
  'deVolta': false,
  'tipo': tipo,
  'texto': null,
  'postId': 'pub-1',
  'chatId': null,
  'lida': lida,
  'criadoEm': '2026-10-27T12:00:00.000Z',
};

class _FakeNotificacoesRepository implements NotificacoesRepository {
  List<Notificacao> servidor = [
    _notificacao('n1'),
    _notificacao('n2'),
    _notificacao('n3'),
  ];
  final List<String> apagadas = [];
  bool falharApagar = false;
  bool falharApagarTodas = false;
  int listagens = 0;
  int marcacoesTodasLidas = 0;
  Completer<List<Notificacao>>? pendente;

  @override
  Future<({List<Notificacao> lista, int naoLidas})> listar({
    int pagina = 1,
    int porPagina = 20,
  }) async {
    listagens++;
    final lista = pendente != null
        ? await pendente!.future
        : List<Notificacao>.unmodifiable(servidor);
    return (lista: lista, naoLidas: 0);
  }

  @override
  Future<int> contarNaoLidas() async => 0;

  @override
  Future<void> marcarTodasComoLidas() async {
    marcacoesTodasLidas++;
  }

  @override
  Future<void> apagar(String id) async {
    if (falharApagar) throw Exception('falha');
    apagadas.add(id);
    servidor = servidor.where((n) => n.id != id).toList();
  }

  @override
  Future<void> apagarTodas() async {
    if (falharApagarTodas) throw Exception('falha');
    servidor = [];
  }
}

class _FakeAuthRepository implements AuthRepository {
  String usuarioId = 'eu';

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
    accessToken: 'token-$usuarioId',
    usuario: Usuario(
      id: usuarioId,
      nome: 'Pescador',
      email: email,
      onboardingConcluido: true,
    ),
  );

  @override
  Future<void> logout() async {}
}

Future<AuthProvider> _logado(String usuarioId) async {
  final auth = AuthProvider(
    repository: _FakeAuthRepository()..usuarioId = usuarioId,
  );
  await auth.login(email: '$usuarioId@teste.com', senha: '123456');
  return auth;
}

void main() {
  late _FakeNotificacoesRepository repo;
  late FakeRealtimeManager realtime;
  late NotificacoesProvider provider;

  List<String> ids() => provider.notificacoes.map((n) => n.id).toList();

  NotificacoesProvider criar(_FakeNotificacoesRepository repository) =>
      NotificacoesProvider(
        repository: repository,
        perfilRepository: PerfilRepositoryMock(),
        realtime: realtime,
      );

  setUp(() async {
    repo = _FakeNotificacoesRepository();
    realtime = FakeRealtimeManager();
    provider = criar(repo);
    await provider.carregar();
  });

  test('removerLocal tira o item da lista sem chamar a API', () {
    final removeu = provider.removerLocal('n2');

    expect(removeu, isTrue);
    expect(ids(), ['n1', 'n3']);
    expect(repo.apagadas, isEmpty);
  });

  test('removerLocal retorna false para um id que não está na lista', () {
    expect(provider.removerLocal('nao-existe'), isFalse);
    expect(ids(), ['n1', 'n2', 'n3']);
  });

  test('desfazerRemocao devolve o item na posição original', () {
    provider.removerLocal('n2');

    provider.desfazerRemocao('n2');

    expect(ids(), ['n1', 'n2', 'n3']);
  });

  test('confirmarRemocao apaga na API', () async {
    provider.removerLocal('n2');

    final apagou = await provider.confirmarRemocao('n2');

    expect(apagou, isTrue);
    expect(repo.apagadas, ['n2']);
    expect(ids(), ['n1', 'n3']);
  });

  test('confirmarRemocao depois do desfazer não chama a API', () async {
    provider.removerLocal('n2');
    provider.desfazerRemocao('n2');

    final apagou = await provider.confirmarRemocao('n2');

    expect(apagou, isTrue);
    expect(repo.apagadas, isEmpty);
    expect(ids(), ['n1', 'n2', 'n3']);
  });

  test('confirmarRemocao com falha na API devolve o item para a lista', () async {
    repo.falharApagar = true;
    provider.removerLocal('n2');

    final apagou = await provider.confirmarRemocao('n2');

    expect(apagou, isFalse);
    expect(ids(), ['n1', 'n2', 'n3']);
  });

  test('refresh não traz de volta um item com remoção pendente', () async {
    provider.removerLocal('n2');

    await provider.refresh();

    expect(ids(), ['n1', 'n3']);
  });

  test('limparTodas apaga na API e esvazia a lista', () async {
    final limpou = await provider.limparTodas();

    expect(limpou, isTrue);
    expect(provider.temAlguma, isFalse);
    expect(repo.servidor, isEmpty);
  });

  test('limparTodas com falha na API mantém a lista', () async {
    repo.falharApagarTodas = true;

    final limpou = await provider.limparTodas();

    expect(limpou, isFalse);
    expect(ids(), ['n1', 'n2', 'n3']);
  });

  test('não notifica depois de descartado', () async {
    provider.removerLocal('n2');
    repo.falharApagar = true;
    provider.dispose();

    expect(await provider.confirmarRemocao('n2'), isFalse);
  });

  group('filtragem de mensagens', () {
    test('carregar() descarta itens do tipo mensagem', () async {
      final repoComMensagens = _FakeNotificacoesRepository()
        ..servidor = [
          Notificacao(
            id: 'social-1',
            para: 'me',
            tipo: TipoNotificacao.curtida,
            lida: false,
            criadoEm: DateTime(2026, 10, 12),
          ),
          Notificacao(
            id: 'msg-1',
            para: 'me',
            tipo: TipoNotificacao.mensagem,
            texto: 'oi',
            lida: false,
            criadoEm: DateTime(2026, 10, 12),
          ),
          Notificacao(
            id: 'social-2',
            para: 'me',
            tipo: TipoNotificacao.seguindo,
            lida: false,
            criadoEm: DateTime(2026, 10, 12),
          ),
        ];
      final providerFiltrado = criar(repoComMensagens);

      await providerFiltrado.carregar();

      final idsVisiveis =
          providerFiltrado.notificacoes.map((n) => n.id).toList();
      expect(idsVisiveis, ['social-1', 'social-2']);
      expect(
        providerFiltrado.notificacoes.any(
          (n) => n.tipo == TipoNotificacao.mensagem,
        ),
        isFalse,
      );
    });
  });

  group('marcar como lidas', () {
    setUp(() async {
      repo.servidor = [
        _notificacao('n1', lida: false),
        _notificacao('n2', lida: false),
        _notificacao('n3'),
      ];
      await provider.refresh();
    });

    test('carregar() sem flag não marca nada no servidor', () async {
      await provider.carregar();

      expect(repo.marcacoesTodasLidas, 0);
      expect(provider.naoVistas, 2);
    });

    test(
      'carregar(marcarComoLidas: true) marca no servidor e zera naoVistas '
      'sem mexer no lida local',
      () async {
        await provider.carregar(marcarComoLidas: true);

        expect(repo.marcacoesTodasLidas, 1);
        expect(provider.naoVistas, 0);
        // `lida: false` local segura o indicador visual da sessão.
        expect(provider.notificacoes.where((n) => !n.lida).map((n) => n.id), [
          'n1',
          'n2',
        ]);
      },
    );

    test('naoVistas zera já no início do carregar, antes da resposta', () async {
      repo.pendente = Completer();

      final carregando = provider.carregar(marcarComoLidas: true);
      expect(provider.naoVistas, 0);

      repo.pendente!.complete(repo.servidor);
      await carregando;
    });

    test('sem nenhuma não lida, não chama o servidor', () async {
      repo.servidor = [_notificacao('n1'), _notificacao('n2')];

      await provider.carregar(marcarComoLidas: true);

      expect(repo.marcacoesTodasLidas, 0);
    });

    test('nova notificação depois de vistas volta a contar', () async {
      await provider.carregar(marcarComoLidas: true);

      realtime.emitir('nova_notificacao', _payload(id: 'nova-1'));

      expect(provider.naoVistas, 1);
    });
  });

  group('nova_notificacao', () {
    test('adiciona no topo com lida: false', () {
      realtime.emitir('nova_notificacao', _payload(id: 'nova-1'));

      expect(ids(), ['nova-1', 'n1', 'n2', 'n3']);
      final nova = provider.notificacoes.first;
      expect(nova.lida, isFalse);
      expect(nova.tipo, TipoNotificacao.curtida);
      expect(nova.deUsername, 'fulano');
      expect(nova.postId, 'pub-1');
    });

    test('notifica os listeners', () {
      var notificou = 0;
      provider.addListener(() => notificou++);

      realtime.emitir('nova_notificacao', _payload());

      expect(notificou, 1);
    });

    test('é idempotente: id já presente não duplica', () {
      realtime.emitir('nova_notificacao', _payload(id: 'nova-1'));
      realtime.emitir('nova_notificacao', _payload(id: 'nova-1'));
      realtime.emitir('nova_notificacao', _payload(id: 'n2'));

      expect(ids(), ['nova-1', 'n1', 'n2', 'n3']);
    });

    test('tipo mensagem é filtrado (TODO 8.4.4)', () {
      realtime.emitir('nova_notificacao', _payload(tipo: 'mensagem'));

      expect(ids(), ['n1', 'n2', 'n3']);
    });

    test('não marca nada como lida no servidor', () {
      realtime.emitir('nova_notificacao', _payload());

      expect(repo.marcacoesTodasLidas, 0);
    });

    test('payload inválido é no-op e não lança', () {
      var notificou = 0;
      provider.addListener(() => notificou++);

      for (final invalido in <dynamic>[
        null,
        'texto',
        42,
        <String, dynamic>{},
        {..._payload(), 'id': null},
        {..._payload(), 'criadoEm': 'não é data'},
      ]) {
        expect(
          () => realtime.emitir('nova_notificacao', invalido),
          returnsNormally,
        );
      }

      expect(ids(), ['n1', 'n2', 'n3']);
      expect(notificou, 0);
    });

    test('dispose desfaz as assinaturas', () {
      final outro = criar(_FakeNotificacoesRepository());
      final assinaturasAntes =
          realtime.assinantes['nova_notificacao']!.length;

      outro.dispose();

      expect(
        realtime.assinantes['nova_notificacao'],
        hasLength(assinaturasAntes - 1),
      );
      expect(realtime.callbacksReconexao, hasLength(1));
    });
  });

  group('reagirAuth', () {
    late _FakeNotificacoesRepository repoAuth;
    late NotificacoesProvider porAuth;

    setUp(() {
      repoAuth = _FakeNotificacoesRepository();
      porAuth = criar(repoAuth);
    });

    test('logado dispara carregar() sem marcar como lidas', () async {
      porAuth.reagirAuth(await _logado('eu'));
      await pumpEventQueue();

      expect(repoAuth.listagens, 1);
      expect(repoAuth.marcacoesTodasLidas, 0);
      expect(porAuth.status, StatusNotificacoes.carregado);
      expect(porAuth.notificacoes, hasLength(3));
    });

    test('outras notificações da mesma conta não recarregam', () async {
      final auth = await _logado('eu');

      porAuth.reagirAuth(auth);
      porAuth.reagirAuth(auth);
      await pumpEventQueue();

      expect(repoAuth.listagens, 1);
    });

    test('deslogado dispara resetar()', () async {
      final auth = await _logado('eu');
      porAuth.reagirAuth(auth);
      await pumpEventQueue();
      porAuth.setFiltro(TipoNotificacao.curtida);

      await auth.signOut();
      porAuth.reagirAuth(auth);

      expect(porAuth.temAlguma, isFalse);
      expect(porAuth.filtro, isNull);
      expect(porAuth.naoVistas, 0);
      expect(porAuth.status, StatusNotificacoes.carregando);
    });

    test(
      'load da conta anterior que chega depois da troca é descartado',
      () async {
        final pendenteAnterior = Completer<List<Notificacao>>();
        repoAuth.pendente = pendenteAnterior;
        porAuth.reagirAuth(await _logado('conta-b'));

        repoAuth.pendente = null;
        repoAuth.servidor = [_notificacao('c1')];
        porAuth.reagirAuth(await _logado('conta-c'));
        await pumpEventQueue();

        pendenteAnterior.complete([_notificacao('b1')]);
        await pumpEventQueue();

        expect(porAuth.notificacoes.map((n) => n.id), ['c1']);
      },
    );
  });

  group('onReconnect', () {
    test('logado dispara refresh()', () async {
      final repoAuth = _FakeNotificacoesRepository();
      final porAuth = criar(repoAuth);
      porAuth.reagirAuth(await _logado('eu'));
      await pumpEventQueue();
      repoAuth.servidor = [_notificacao('n9'), ...repoAuth.servidor];

      realtime.simularReconexao();
      await pumpEventQueue();

      expect(repoAuth.listagens, 2);
      expect(porAuth.notificacoes.first.id, 'n9');
    });

    test('deslogado não busca nada', () async {
      final repoAuth = _FakeNotificacoesRepository();
      criar(repoAuth);

      realtime.simularReconexao();
      await pumpEventQueue();

      expect(repoAuth.listagens, 0);
    });
  });
}
