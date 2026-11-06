import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_exceptions.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_api_client.dart';
import 'package:pesque_fale_app/features/perfil/domain/perfil_completo.dart';
import 'package:pesque_fale_app/features/perfil/providers/perfil_provider.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';

import '../../chat/support/fake_realtime_manager.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async {
    return const AuthResult(
      accessToken: 'token',
      usuario: Usuario(
        id: 'eu',
        nome: 'Eu Mesmo',
        email: 'eu@teste.com',
        onboardingConcluido: true,
      ),
    );
  }

  @override
  Future<void> logout() async {}
}

class _FakePerfilRepository implements PerfilRepository {
  _FakePerfilRepository({
    this.falharAoSeguir = false,
    this.isFollowing = false,
    this.seguidoPeloOutro = false,
    this.usuarioId = 'outro',
    this.publicacoes = const [],
    this.totalPublicacoes,
  });

  final bool falharAoSeguir;
  final bool isFollowing;
  final bool seguidoPeloOutro;
  final String usuarioId;
  final List<Publicacao> publicacoes;
  final int? totalPublicacoes;

  Usuario get _outro => Usuario(
    id: usuarioId,
    nome: 'Outro Pescador',
    email: 'outro@teste.com',
    onboardingConcluido: true,
    seguidores: 10,
  );

  @override
  Future<PerfilCompleto> buscarPerfil(
    String id, {
    required String meuId,
  }) async {
    return PerfilCompleto(
      usuario: _outro,
      publicacoes: publicacoes,
      isFollowing: isFollowing,
      seguidoPeloOutro: seguidoPeloOutro,
      totalPublicacoes: totalPublicacoes,
    );
  }

  @override
  Future<void> seguir(String id) async {
    if (falharAoSeguir) throw const InternalServerException();
  }

  @override
  Future<void> deixarDeSeguir(String id) async {
    if (falharAoSeguir) throw const InternalServerException();
  }

  @override
  Future<String> atualizarFoto(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async => 'https://x/foto.png';

  @override
  Future<String> atualizarBanner(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async => 'https://x/banner.png';

  @override
  Future<Usuario> editarPerfil(Map<String, dynamic> camposAlterados) async {
    return _outro;
  }

  @override
  Future<bool> verificarUsername(String username) async => true;

  @override
  Future<ListaPaginada<UsuarioResumido>> buscarSeguidores(
    String id, {
    int pagina = 1,
    int porPagina = 20,
  }) async => throw UnimplementedError();

  @override
  Future<ListaPaginada<UsuarioResumido>> buscarSeguindo(
    String id, {
    int pagina = 1,
    int porPagina = 20,
  }) async => throw UnimplementedError();
}

void main() {
  late AuthProvider authProvider;

  setUp(() async {
    authProvider = AuthProvider(repository: _FakeAuthRepository());
    await authProvider.login(email: 'eu@teste.com', senha: '123456');
  });

  group('PerfilProvider.carregarPerfil', () {
    test('hidrata perfil e publicacoes com sucesso', () async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(),
        authProvider: authProvider,
        store: PublicacoesStore(),
      );

      await provider.carregarPerfil('outro');

      expect(provider.status, PerfilStatus.success);
      expect(provider.perfil?.id, 'outro');
      expect(provider.isOwnProfile, isFalse);
    });
  });

  group('PerfilProvider.seguir', () {
    test('atualiza otimisticamente e mantém em caso de sucesso', () async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(),
        authProvider: authProvider,
        store: PublicacoesStore(),
      );
      await provider.carregarPerfil('outro');

      final ok = await provider.seguir();

      expect(ok, isTrue);
      expect(provider.isFollowing, isTrue);
      expect(provider.perfil?.seguidores, 11);
    });

    test(
      'faz rollback do estado e do contador quando a chamada falha',
      () async {
        final provider = PerfilProvider(
          repository: _FakePerfilRepository(falharAoSeguir: true),
          authProvider: authProvider,
          store: PublicacoesStore(),
        );
        await provider.carregarPerfil('outro');

        final ok = await provider.seguir();

        expect(ok, isFalse);
        expect(provider.isFollowing, isFalse);
        expect(provider.perfil?.seguidores, 10);
        expect(provider.errorMessage, isNotNull);
      },
    );
  });

  group('PerfilProvider.abrirChat', () {
    test('gera chatId ordenado independente da ordem dos ids', () async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(),
        authProvider: authProvider,
        store: PublicacoesStore(),
      );
      await provider.carregarPerfil('outro');

      expect(provider.abrirChat(), 'eu_outro');
    });
  });

  // Regra: mutual follow exige as duas direções (backend enforça isso via
  // chat.gateway.js — `verificarMutualFollow` só passa com as duas linhas em
  // `usuario_seguidores`).
  group('PerfilProvider.chatLiberado', () {
    test('é false quando apenas eu sigo o outro', () async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(isFollowing: true),
        authProvider: authProvider,
        store: PublicacoesStore(),
      );
      await provider.carregarPerfil('outro');

      expect(provider.chatLiberado, isFalse);
    });

    test('é false quando apenas o outro me segue', () async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(seguidoPeloOutro: true),
        authProvider: authProvider,
        store: PublicacoesStore(),
      );
      await provider.carregarPerfil('outro');

      expect(provider.chatLiberado, isFalse);
    });

    test('é true apenas quando ambos se seguem', () async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(
          isFollowing: true,
          seguidoPeloOutro: true,
        ),
        authProvider: authProvider,
        store: PublicacoesStore(),
      );
      await provider.carregarPerfil('outro');

      expect(provider.chatLiberado, isTrue);
    });
  });

  group('PerfilProvider.mostrarHintMutualFollow', () {
    test('é true quando eu sigo e o outro não me segue de volta', () async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(isFollowing: true),
        authProvider: authProvider,
        store: PublicacoesStore(),
      );
      await provider.carregarPerfil('outro');

      expect(provider.mostrarHintMutualFollow, isTrue);
    });

    test('é false quando ambos se seguem', () async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(
          isFollowing: true,
          seguidoPeloOutro: true,
        ),
        authProvider: authProvider,
        store: PublicacoesStore(),
      );
      await provider.carregarPerfil('outro');

      expect(provider.mostrarHintMutualFollow, isFalse);
    });

    test('é false no próprio perfil', () async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(usuarioId: 'eu', isFollowing: true),
        authProvider: authProvider,
        store: PublicacoesStore(),
      );
      await provider.carregarPerfil('eu');

      expect(provider.isOwnProfile, isTrue);
      expect(provider.mostrarHintMutualFollow, isFalse);
    });
  });

  group('PerfilProvider.podeSeguirDeVolta', () {
    test('é true quando o outro me segue e eu não sigo', () async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(seguidoPeloOutro: true),
        authProvider: authProvider,
        store: PublicacoesStore(),
      );
      await provider.carregarPerfil('outro');

      expect(provider.podeSeguirDeVolta, isTrue);
    });

    test('é false quando eu já sigo', () async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(
          isFollowing: true,
          seguidoPeloOutro: true,
        ),
        authProvider: authProvider,
        store: PublicacoesStore(),
      );
      await provider.carregarPerfil('outro');

      expect(provider.podeSeguirDeVolta, isFalse);
    });

    test('é false quando o outro não me segue', () async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(),
        authProvider: authProvider,
        store: PublicacoesStore(),
      );
      await provider.carregarPerfil('outro');

      expect(provider.podeSeguirDeVolta, isFalse);
    });

    test('é false no próprio perfil', () async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(
          usuarioId: 'eu',
          seguidoPeloOutro: true,
        ),
        authProvider: authProvider,
        store: PublicacoesStore(),
      );
      await provider.carregarPerfil('eu');

      expect(provider.isOwnProfile, isTrue);
      expect(provider.podeSeguirDeVolta, isFalse);
    });

    test('vira false e libera o chat depois de seguir de volta', () async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(seguidoPeloOutro: true),
        authProvider: authProvider,
        store: PublicacoesStore(),
      );
      await provider.carregarPerfil('outro');

      final ok = await provider.seguir();

      expect(ok, isTrue);
      expect(provider.podeSeguirDeVolta, isFalse);
      expect(provider.chatLiberado, isTrue);
    });
  });

  group('PerfilProvider realtime de seguidores', () {
    late FakeRealtimeManager realtime;

    setUp(() => realtime = FakeRealtimeManager(conectado: true));

    void disparar(String evento, dynamic payload) {
      for (final cb in List.of(realtime.assinantes[evento] ?? const [])) {
        cb(payload);
      }
    }

    Map<String, dynamic> payload(dynamic total, {String acao = 'adicionado'}) =>
        {'totalSeguidores': total, 'seguidorId': 'fulano', 'acao': acao};

    PerfilProvider criar({String usuarioId = 'eu'}) => PerfilProvider(
      repository: _FakePerfilRepository(usuarioId: usuarioId),
      authProvider: authProvider,
      store: PublicacoesStore(),
      realtime: realtime,
    );

    test('seguidor_adicionado no próprio perfil atualiza o contador', () async {
      final provider = criar();
      await provider.carregarPerfil('eu');
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      disparar('seguidor_adicionado', payload(11));

      expect(provider.perfil?.seguidores, 11);
      expect(notificacoes, 1);
    });

    test('seguidor_adicionado no perfil de outro é no-op', () async {
      final provider = criar(usuarioId: 'outro');
      await provider.carregarPerfil('outro');
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      disparar('seguidor_adicionado', payload(99));

      expect(provider.perfil?.seguidores, 10);
      expect(notificacoes, 0);
    });

    test('seguidor_removido no próprio perfil atualiza o contador', () async {
      final provider = criar();
      await provider.carregarPerfil('eu');

      disparar('seguidor_removido', payload(9, acao: 'removido'));

      expect(provider.perfil?.seguidores, 9);
    });

    test('evento sem perfil carregado é no-op', () {
      final provider = criar();
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      disparar('seguidor_adicionado', payload(11));

      expect(provider.perfil, isNull);
      expect(notificacoes, 0);
    });

    test('total igual ao atual não notifica', () async {
      final provider = criar();
      await provider.carregarPerfil('eu');
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      disparar('seguidor_adicionado', payload(10));

      expect(provider.perfil?.seguidores, 10);
      expect(notificacoes, 0);
    });

    test('payload inválido é no-op', () async {
      final provider = criar();
      await provider.carregarPerfil('eu');
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      disparar('seguidor_adicionado', payload(null));
      disparar('seguidor_adicionado', payload('11'));
      disparar('seguidor_removido', 'lixo');
      disparar('seguidor_removido', null);

      expect(provider.perfil?.seguidores, 10);
      expect(notificacoes, 0);
    });

    test('dispose desinscreve dos dois eventos', () {
      final provider = criar();
      expect(realtime.assinantes['seguidor_adicionado'], hasLength(1));
      expect(realtime.assinantes['seguidor_removido'], hasLength(1));

      provider.dispose();

      expect(realtime.assinantes['seguidor_adicionado'], isEmpty);
      expect(realtime.assinantes['seguidor_removido'], isEmpty);
    });
  });

  group('PerfilProvider com PublicacoesStore', () {
    late PublicacoesStore store;

    Publicacao pub(
      String id, {
      String autorId = 'outro',
      String autorNome = '',
      bool jaCurtiu = false,
      int dia = 1,
    }) => Publicacao(
      id: id,
      autorId: autorId,
      autorNome: autorNome,
      jaCurtiu: jaCurtiu,
      criadoEm: DateTime(2026, 1, dia),
      atualizadoEm: DateTime(2026, 1, dia),
    );

    Future<PerfilProvider> carregar(
      List<Publicacao> publicacoes, {
      int? total,
    }) async {
      final provider = PerfilProvider(
        repository: _FakePerfilRepository(
          publicacoes: publicacoes,
          totalPublicacoes: total,
        ),
        authProvider: authProvider,
        store: store,
      );
      await provider.carregarPerfil('outro');
      return provider;
    }

    setUp(() => store = PublicacoesStore());

    test('coloca as publicações no store com o nome do dono', () async {
      final provider = await carregar([pub('p1', dia: 2), pub('p2')]);

      expect(provider.publicacoes.map((p) => p.id), ['p1', 'p2']);
      expect(provider.totalPublicacoes, 2);
      expect(store.porId('p1')!.autorNome, 'Outro Pescador');
    });

    test('não sobrescreve o que o feed já trouxe', () async {
      store.upsert(pub('p1', autorNome: 'Nome do feed', jaCurtiu: true));

      final provider = await carregar([pub('p1')]);

      expect(store.porId('p1')!.jaCurtiu, isTrue);
      expect(store.porId('p1')!.autorNome, 'Nome do feed');
      expect(provider.publicacoes.single.jaCurtiu, isTrue);
    });

    test('excluir em outra tela tira da galeria e do contador', () async {
      final provider = await carregar([pub('p1', dia: 2), pub('p2')]);
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      store.remover('p1');

      expect(provider.publicacoes.map((p) => p.id), ['p2']);
      expect(provider.totalPublicacoes, 1);
      expect(notificacoes, greaterThan(0));
    });

    test('publicação nova do dono entra no topo e no contador', () async {
      final provider = await carregar([pub('p1')]);

      store.upsert(pub('p2', autorNome: 'Outro Pescador', dia: 5));

      expect(provider.publicacoes.map((p) => p.id), ['p2', 'p1']);
      expect(provider.totalPublicacoes, 2);
    });

    test('publicação antiga do dono vinda do feed não entra', () async {
      final provider = await carregar([pub('p2', dia: 5)]);

      store.upsert(pub('p1', autorNome: 'Outro Pescador', dia: 1));

      expect(provider.publicacoes.map((p) => p.id), ['p2']);
    });

    test('publicação de outro autor não entra', () async {
      final provider = await carregar([pub('p1')]);

      store.upsert(pub('p9', autorId: 'terceiro', autorNome: 'X', dia: 9));

      expect(provider.publicacoes.map((p) => p.id), ['p1']);
    });

    test('curtida feita em outra tela aparece na galeria', () async {
      final provider = await carregar([pub('p1')]);

      store.atualizarCurtida('p1', jaCurtiu: true, curtidasCount: 1);

      expect(provider.publicacoes.single.curtidasCount, 1);
    });

    group('totalPublicacoes', () {
      // 12 publicações carregadas (primeira página), dias 1 a 12.
      List<Publicacao> primeiraPagina() => [
        for (var i = 12; i >= 1; i--) pub('p$i', dia: i),
      ];

      test('usa o total da API, não o tamanho da primeira página', () async {
        final provider = await carregar(primeiraPagina(), total: 30);

        expect(provider.publicacoes, hasLength(12));
        expect(provider.totalPublicacoes, 30);
      });

      test('publicação nova do dono soma no total', () async {
        final provider = await carregar(primeiraPagina(), total: 30);

        store.upsert(pub('nova', autorNome: 'Outro Pescador', dia: 20));

        expect(provider.publicacoes.first.id, 'nova');
        expect(provider.totalPublicacoes, 31);
      });

      test('excluir uma publicação carregada subtrai do total', () async {
        final provider = await carregar(primeiraPagina(), total: 30);

        store.remover('p5');

        expect(provider.publicacoes, hasLength(11));
        expect(provider.totalPublicacoes, 29);
      });

      test(
        'excluir a mesma publicação de novo não subtrai duas vezes',
        () async {
          final provider = await carregar(primeiraPagina(), total: 30);

          store.remover('p5');
          store.remover('p5');

          expect(provider.totalPublicacoes, 29);
        },
      );

      test(
        'excluir publicação que não está no perfil não mexe no total',
        () async {
          final provider = await carregar(primeiraPagina(), total: 30);
          store.upsert(pub('p9x', autorId: 'terceiro', autorNome: 'X', dia: 9));

          store.remover('p9x');

          expect(provider.totalPublicacoes, 30);
        },
      );

      test('nunca fica negativo', () async {
        final provider = await carregar([pub('p1')], total: 0);

        store.remover('p1');

        expect(provider.totalPublicacoes, 0);
      });

      test('sem total no PerfilCompleto cai para o tamanho da lista', () async {
        final provider = await carregar([pub('p1', dia: 2), pub('p2')]);

        expect(provider.totalPublicacoes, 2);
      });

      test('recarregar o perfil volta ao total da API', () async {
        final provider = await carregar(primeiraPagina(), total: 30);
        store.remover('p5');
        expect(provider.totalPublicacoes, 29);

        await provider.carregarPerfil('outro');

        expect(provider.totalPublicacoes, 30);
      });
    });

    test('dispose deixa de escutar o store', () async {
      final provider = await carregar([pub('p1')]);

      provider.dispose();

      expect(() => store.remover('p1'), returnsNormally);
    });
  });
}
