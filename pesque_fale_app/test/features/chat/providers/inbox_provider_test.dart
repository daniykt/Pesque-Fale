import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/realtime/realtime_manager.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/chat/data/conversas_repository.dart';
import 'package:pesque_fale_app/features/chat/domain/conversa.dart';
import 'package:pesque_fale_app/features/chat/providers/badge_mensagens_provider.dart';
import 'package:pesque_fale_app/features/chat/providers/inbox_provider.dart';

import '../support/fake_realtime_manager.dart';

class _FakeConversasRepository implements ConversasRepository {
  _FakeConversasRepository({this.conversas = const [], this.falhar = false});

  List<Conversa> conversas;
  bool falhar;
  int chamadas = 0;
  Completer<List<Conversa>>? pendente;

  @override
  Future<List<Conversa>> listar() async {
    chamadas++;
    if (pendente != null) return pendente!.future;
    if (falhar) throw Exception('erro');
    return conversas;
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

Conversa _conversa({
  required String id,
  required String nome,
  required String username,
  String? ultimaMensagem = 'oi',
  DateTime? ultimaMensagemEm,
  int naoLidas = 0,
}) {
  final agora = DateTime(2026, 5, 28);
  return Conversa(
    id: id,
    outroId: 'user-$id',
    outroNome: nome,
    outroUsername: username,
    ultimaMensagem: ultimaMensagem,
    ultimaMensagemEm: ultimaMensagem != null
        ? (ultimaMensagemEm ?? agora)
        : null,
    naoLidas: naoLidas,
    criadoEm: agora,
  );
}

Map<String, dynamic> _novaConversa({
  String conversaId = 'eu_henrique',
  String remetenteId = 'henrique',
  String texto = 'e aí, bora pescar?',
  String criadoEm = '2026-10-27T12:00:00.000Z',
}) => {
  'conversaId': conversaId,
  'remetente': {
    'id': remetenteId,
    'nome': 'Henrique',
    'username': 'rique',
    'fotoUrl': 'http://foto/rique.png',
  },
  'ultimaMensagem': {
    'id': 'msg-1',
    'chatId': conversaId,
    'userId': remetenteId,
    'nome': 'Henrique',
    'texto': texto,
    'status': 'enviado',
    'criadoEm': criadoEm,
  },
};

Map<String, dynamic> _preview({
  required String conversaId,
  required String remetenteId,
  String texto = 'nova',
  String timestamp = '2026-10-27T13:00:00.000Z',
}) => {
  'conversaId': conversaId,
  'previewTexto': texto,
  'timestamp': timestamp,
  'remetenteId': remetenteId,
};

Future<AuthProvider> _logado(String usuarioId) async {
  final auth = AuthProvider(
    repository: _FakeAuthRepository()..usuarioId = usuarioId,
  );
  await auth.login(email: '$usuarioId@teste.com', senha: '123456');
  return auth;
}

void main() {
  late FakeRealtimeManager realtime;

  setUp(() => realtime = FakeRealtimeManager());

  InboxProvider criar(ConversasRepository repo) =>
      InboxProvider(repository: repo, realtime: realtime);

  group('InboxProvider', () {
    test('carregar popula conversas e filtra chats vazios', () async {
      final repo = _FakeConversasRepository(
        conversas: [
          _conversa(id: '1', nome: 'Henrique Tavares', username: 'rique'),
          _conversa(
            id: '2',
            nome: 'João Pedro',
            username: 'joaop',
            ultimaMensagem: null,
          ),
        ],
      );
      final provider = criar(repo);

      await provider.carregar();

      expect(provider.status, StatusInbox.carregado);
      expect(provider.conversas, hasLength(1));
      expect(provider.conversasInternas, hasLength(2));
      expect(provider.temAlgumaConversa, isTrue);
    });

    test('carregar com falha define status de erro', () async {
      final provider = criar(_FakeConversasRepository(falhar: true));

      await provider.carregar();

      expect(provider.status, StatusInbox.erro);
    });

    test('busca filtra por nome ou username, case-insensitive', () async {
      final repo = _FakeConversasRepository(
        conversas: [
          _conversa(id: '1', nome: 'Henrique Tavares', username: 'rique'),
          _conversa(id: '2', nome: 'Beatriz Fisher', username: 'bia_fisher'),
        ],
      );
      final provider = criar(repo);
      await provider.carregar();

      provider.setTermoBusca('HENRIQUE');
      expect(provider.conversas.map((c) => c.id), ['1']);
      expect(provider.conversasInternas, hasLength(2));

      provider.setTermoBusca('bia_fisher');
      expect(provider.conversas.map((c) => c.id), ['2']);

      provider.setTermoBusca('inexistente');
      expect(provider.conversas, isEmpty);

      provider.setTermoBusca('');
      expect(provider.conversas, hasLength(2));
    });

    test('refresh mantém dados anteriores quando falha', () async {
      final repo = _FakeConversasRepository(
        conversas: [_conversa(id: '1', nome: 'Ana', username: 'ana')],
      );
      final provider = criar(repo);
      await provider.carregar();

      repo.falhar = true;
      await provider.refresh();

      expect(provider.status, StatusInbox.carregado);
      expect(provider.conversas, hasLength(1));
    });

    test('conversasInternas não pode ser modificada por fora', () async {
      final provider = criar(
        _FakeConversasRepository(
          conversas: [_conversa(id: '1', nome: 'Ana', username: 'ana')],
        ),
      );
      await provider.carregar();

      expect(
        () => provider.conversasInternas.add(
          _conversa(id: '2', nome: 'B', username: 'b'),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('reagirAuth', () {
    test('logado dispara carregar()', () async {
      final repo = _FakeConversasRepository(
        conversas: [_conversa(id: '1', nome: 'Ana', username: 'ana')],
      );
      final provider = criar(repo);

      provider.reagirAuth(await _logado('eu'));
      await pumpEventQueue();

      expect(repo.chamadas, 1);
      expect(provider.status, StatusInbox.carregado);
      expect(provider.conversas, hasLength(1));
    });

    test('outras notificações da mesma conta não recarregam', () async {
      final repo = _FakeConversasRepository();
      final provider = criar(repo);
      final auth = await _logado('eu');

      provider.reagirAuth(auth);
      provider.reagirAuth(auth);
      await pumpEventQueue();

      expect(repo.chamadas, 1);
    });

    test('deslogado dispara resetar()', () async {
      final repo = _FakeConversasRepository(
        conversas: [_conversa(id: '1', nome: 'Ana', username: 'ana')],
      );
      final provider = criar(repo);
      final auth = await _logado('eu');
      provider.reagirAuth(auth);
      await pumpEventQueue();
      provider.setTermoBusca('ana');

      await auth.signOut();
      provider.reagirAuth(auth);

      expect(provider.conversasInternas, isEmpty);
      expect(provider.termoBusca, isEmpty);
      expect(provider.status, StatusInbox.carregando);
    });

    test(
      'load da conta anterior que chega depois da troca é descartado',
      () async {
        final repo = _FakeConversasRepository();
        final provider = criar(repo);
        final pendenteAnterior = Completer<List<Conversa>>();
        repo.pendente = pendenteAnterior;
        provider.reagirAuth(await _logado('conta-b'));

        repo.pendente = null;
        repo.conversas = [
          _conversa(id: 'c1', nome: 'Carla', username: 'carla'),
        ];
        provider.reagirAuth(await _logado('conta-c'));
        await pumpEventQueue();

        pendenteAnterior.complete([
          _conversa(id: 'b1', nome: 'Bruno', username: 'bruno'),
        ]);
        await pumpEventQueue();

        expect(provider.conversas.map((c) => c.id), ['c1']);
      },
    );
  });

  group('eventos realtime', () {
    Future<InboxProvider> logadoCom(
      List<Conversa> conversas, {
      String meuId = 'eu',
      _FakeConversasRepository? repo,
    }) async {
      final provider = criar(
        (repo ?? _FakeConversasRepository())..conversas = conversas,
      );
      provider.reagirAuth(await _logado(meuId));
      await pumpEventQueue();
      return provider;
    }

    test(
      'nova_conversa adiciona a conversa no topo quando não existe',
      () async {
        final provider = await logadoCom([
          _conversa(id: 'antiga', nome: 'Ana', username: 'ana'),
        ]);
        var notificacoes = 0;
        provider.addListener(() => notificacoes++);

        realtime.emitir('nova_conversa', _novaConversa());

        expect(provider.conversas.map((c) => c.id), ['eu_henrique', 'antiga']);
        final nova = provider.conversas.first;
        expect(nova.outroId, 'henrique');
        expect(nova.outroNome, 'Henrique');
        expect(nova.outroUsername, 'rique');
        expect(nova.outroFoto, 'http://foto/rique.png');
        expect(nova.ultimaMensagem, 'e aí, bora pescar?');
        expect(
          nova.ultimaMensagemEm!.isAtSameMomentAs(
            DateTime.utc(2026, 10, 27, 12),
          ),
          isTrue,
        );
        expect(nova.naoLidas, 1);
        expect(notificacoes, 1);
      },
    );

    test('nova_conversa é idempotente quando a conversa já existe', () async {
      final provider = await logadoCom([
        _conversa(id: 'eu_henrique', nome: 'Henrique', username: 'rique'),
      ]);
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      realtime.emitir('nova_conversa', _novaConversa());

      expect(provider.conversasInternas, hasLength(1));
      expect(provider.conversas.single.ultimaMensagem, 'oi');
      expect(notificacoes, 0);
    });

    test(
      'nova_conversa em que eu sou o remetente busca a lista no backend',
      () async {
        final repo = _FakeConversasRepository();
        final provider = await logadoCom([], repo: repo);
        // O "outro" da conversa é o destinatário, que não vem no payload.
        repo.conversas = [
          _conversa(id: 'eu_henrique', nome: 'Henrique', username: 'rique'),
        ];

        realtime.emitir('nova_conversa', _novaConversa(remetenteId: 'eu'));
        await pumpEventQueue();

        expect(repo.chamadas, 2);
        expect(provider.conversas.single.outroNome, 'Henrique');
      },
    );

    test(
      'nova_mensagem_em_conversa move pro topo e atualiza o preview',
      () async {
        final provider = await logadoCom([
          _conversa(id: 'a', nome: 'Ana', username: 'ana'),
          _conversa(id: 'b', nome: 'Bia', username: 'bia'),
        ]);

        realtime.emitir(
          'nova_mensagem_em_conversa',
          _preview(conversaId: 'b', remetenteId: 'bia', texto: 'chegou'),
        );

        expect(provider.conversas.map((c) => c.id), ['b', 'a']);
        expect(provider.conversas.first.ultimaMensagem, 'chegou');
        expect(
          provider.conversas.first.ultimaMensagemEm!.isAtSameMomentAs(
            DateTime.utc(2026, 10, 27, 13),
          ),
          isTrue,
        );
      },
    );

    test(
      'nova_mensagem_em_conversa incrementa naoLidas quando sou destinatário',
      () async {
        final provider = await logadoCom([
          _conversa(id: 'a', nome: 'Ana', username: 'ana', naoLidas: 2),
        ]);

        realtime.emitir(
          'nova_mensagem_em_conversa',
          _preview(conversaId: 'a', remetenteId: 'ana'),
        );

        expect(provider.conversas.single.naoLidas, 3);
      },
    );

    test(
      'nova_mensagem_em_conversa NÃO incrementa naoLidas quando sou remetente',
      () async {
        final provider = await logadoCom([
          _conversa(id: 'a', nome: 'Ana', username: 'ana'),
        ]);

        realtime.emitir(
          'nova_mensagem_em_conversa',
          _preview(conversaId: 'a', remetenteId: 'eu', texto: 'minha'),
        );

        expect(provider.conversas.single.naoLidas, 0);
        expect(provider.conversas.single.ultimaMensagem, 'minha');
      },
    );

    test(
      'a primeira mensagem (nova_conversa + preview) conta uma vez só',
      () async {
        final provider = await logadoCom([]);

        realtime.emitir('nova_conversa', _novaConversa());
        realtime.emitir(
          'nova_mensagem_em_conversa',
          _preview(
            conversaId: 'eu_henrique',
            remetenteId: 'henrique',
            texto: 'e aí, bora pescar?',
            timestamp: '2026-10-27T12:00:00.000Z',
          ),
        );

        expect(provider.conversas.single.naoLidas, 1);
      },
    );

    test(
      'nova_mensagem_em_conversa de conversa desconhecida é ignorada',
      () async {
        final provider = await logadoCom([
          _conversa(id: 'a', nome: 'Ana', username: 'ana'),
        ]);
        var notificacoes = 0;
        provider.addListener(() => notificacoes++);

        realtime.emitir(
          'nova_mensagem_em_conversa',
          _preview(conversaId: 'x', remetenteId: 'x'),
        );

        expect(provider.conversas.map((c) => c.id), ['a']);
        expect(notificacoes, 0);
      },
    );

    test('onReconnect dispara refresh()', () async {
      final repo = _FakeConversasRepository();
      final provider = await logadoCom([], repo: repo);
      repo.conversas = [_conversa(id: 'a', nome: 'Ana', username: 'ana')];

      realtime.simularReconexao();
      await pumpEventQueue();

      expect(repo.chamadas, 2);
      expect(provider.conversas, hasLength(1));
    });

    test('dispose desfaz as assinaturas no manager', () {
      final provider = criar(_FakeConversasRepository());
      expect(realtime.assinantes['nova_conversa'], hasLength(1));
      expect(realtime.assinantes['nova_mensagem_em_conversa'], hasLength(1));
      expect(realtime.callbacksReconexao, hasLength(1));

      provider.dispose();

      expect(realtime.assinantes['nova_conversa'], isEmpty);
      expect(realtime.assinantes['nova_mensagem_em_conversa'], isEmpty);
      expect(realtime.callbacksReconexao, isEmpty);
    });
  });

  testWidgets(
    'montado como no main.dart: evento sobe o badge e logout zera sem erro',
    (tester) async {
      final repo = _FakeConversasRepository();
      final auth = AuthProvider(repository: _FakeAuthRepository());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProxyProvider<AuthProvider, RealtimeManager>(
              lazy: false,
              create: (_) => realtime,
              update: (_, auth, previous) => previous!..reagirAuth(auth),
            ),
            ChangeNotifierProxyProvider2<
              AuthProvider,
              RealtimeManager,
              InboxProvider
            >(
              lazy: false,
              create: (ctx) => InboxProvider(
                repository: repo,
                realtime: ctx.read<RealtimeManager>(),
              ),
              update: (_, auth, _, previous) => previous!..reagirAuth(auth),
            ),
            ChangeNotifierProxyProvider<InboxProvider, BadgeMensagensProvider>(
              create: (ctx) =>
                  BadgeMensagensProvider(inbox: ctx.read<InboxProvider>()),
              update: (_, inbox, previous) =>
                  previous ?? BadgeMensagensProvider(inbox: inbox),
            ),
          ],
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (context) => Text(
                'badge ${context.watch<BadgeMensagensProvider>().naoLidas}',
              ),
            ),
          ),
        ),
      );

      await tester.runAsync(
        () => auth.login(email: 'eu@teste.com', senha: '123456'),
      );
      await tester.pumpAndSettle();
      expect(find.text('badge 0'), findsOneWidget);

      realtime.emitir('nova_conversa', _novaConversa());
      await tester.pump();
      expect(find.text('badge 1'), findsOneWidget);

      await tester.runAsync(auth.signOut);
      await tester.pumpAndSettle();
      expect(find.text('badge 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
