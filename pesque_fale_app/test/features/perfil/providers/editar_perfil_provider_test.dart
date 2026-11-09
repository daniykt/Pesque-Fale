import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_exceptions.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_api_client.dart';
import 'package:pesque_fale_app/features/perfil/domain/perfil_completo.dart';
import 'package:pesque_fale_app/features/perfil/domain/username_check_state.dart';
import 'package:pesque_fale_app/features/perfil/providers/editar_perfil_provider.dart';

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
  }) async {
    return const AuthResult(
      accessToken: 'token',
      usuario: Usuario(
        id: '1',
        nome: 'Ana',
        email: 'ana@teste.com',
        username: 'ana_original',
        bio: 'Bio original',
        localizacao: 'Floripa',
        onboardingConcluido: true,
      ),
    );
  }

  @override
  Future<void> logout() async {}
}

class _FakePerfilRepository implements PerfilRepository {
  _FakePerfilRepository({
    this.usernamesIndisponiveis = const {},
    this.falharAoEditar = false,
  });

  final Set<String> usernamesIndisponiveis;
  final bool falharAoEditar;
  int chamadasVerificarUsername = 0;
  final uploads =
      <({String tipo, Uint8List bytes, String filename, String mimeType})>[];
  Map<String, dynamic>? ultimosCamposEditados;

  @override
  Future<PerfilCompleto> buscarPerfil(
    String id, {
    required String meuId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> seguir(String id) async {}

  @override
  Future<void> deixarDeSeguir(String id) async {}

  @override
  Future<String> atualizarFoto(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async {
    uploads.add((
      tipo: 'foto',
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    ));
    return 'https://x/foto.png';
  }

  @override
  Future<String> atualizarBanner(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async {
    uploads.add((
      tipo: 'banner',
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    ));
    return 'https://x/banner.png';
  }

  @override
  Future<Usuario> editarPerfil(Map<String, dynamic> camposAlterados) async {
    ultimosCamposEditados = camposAlterados;
    if (falharAoEditar) {
      throw PerfilValidationException({'nome': 'Nome inválido.'});
    }
    return Usuario(
      id: '1',
      nome: camposAlterados['nome'] as String? ?? 'Ana',
      email: 'ana@teste.com',
      username: camposAlterados['username'] as String? ?? 'ana_original',
      bio: camposAlterados['bio'] as String? ?? 'Bio original',
      localizacao: camposAlterados['localizacao'] as String? ?? 'Floripa',
      onboardingConcluido: true,
    );
  }

  @override
  Future<bool> verificarUsername(String username) async {
    chamadasVerificarUsername++;
    await Future.delayed(const Duration(milliseconds: 50));
    return !usernamesIndisponiveis.contains(username);
  }

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
    await authProvider.login(email: 'ana@teste.com', senha: '123456');
  });

  group('EditarPerfilProvider - hidratacao', () {
    test('hidrata campos a partir do usuario logado', () {
      final provider = EditarPerfilProvider(
        repository: _FakePerfilRepository(),
        authProvider: authProvider,
      );

      expect(provider.nome, 'Ana');
      expect(provider.username, 'ana_original');
      expect(provider.temAlteracoes, isFalse);
      expect(provider.usernameState, UsernameCheckState.atual);
    });
  });

  group('EditarPerfilProvider - dirty tracking', () {
    test('temAlteracoes reflete mudanca de campo', () {
      final provider = EditarPerfilProvider(
        repository: _FakePerfilRepository(),
        authProvider: authProvider,
      );

      provider.onNomeChanged('Ana Nova');
      expect(provider.temAlteracoes, isTrue);

      provider.onNomeChanged('Ana');
      expect(provider.temAlteracoes, isFalse);
    });

    test('foto e banner cortados marcam alteracao e notificam', () {
      final provider = EditarPerfilProvider(
        repository: _FakePerfilRepository(),
        authProvider: authProvider,
      );
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      provider.setFotoCortada(Uint8List.fromList([1, 2, 3]));
      expect(provider.novaFotoBytes, [1, 2, 3]);
      expect(provider.temAlteracoes, isTrue);

      provider.setBannerCortado(Uint8List.fromList([4, 5, 6]));
      expect(provider.novoBannerBytes, [4, 5, 6]);
      expect(notificacoes, 2);
    });
  });

  group('EditarPerfilProvider - username debounce', () {
    test('so chama a API uma vez apos digitacao rapida', () async {
      final repository = _FakePerfilRepository();
      final provider = EditarPerfilProvider(
        repository: repository,
        authProvider: authProvider,
      );

      provider.onUsernameChanged('novo1');
      provider.onUsernameChanged('novo12');
      provider.onUsernameChanged('novo123');

      await Future.delayed(const Duration(milliseconds: 700));

      expect(repository.chamadasVerificarUsername, 1);
      expect(provider.usernameState, UsernameCheckState.disponivel);
    });

    test(
      'estado atual quando username volta ao original sem chamar API',
      () async {
        final repository = _FakePerfilRepository();
        final provider = EditarPerfilProvider(
          repository: repository,
          authProvider: authProvider,
        );

        provider.onUsernameChanged('ana_original');
        await Future.delayed(const Duration(milliseconds: 700));

        expect(provider.usernameState, UsernameCheckState.atual);
        expect(repository.chamadasVerificarUsername, 0);
      },
    );

    test('formato invalido nao chama a API', () async {
      final repository = _FakePerfilRepository();
      final provider = EditarPerfilProvider(
        repository: repository,
        authProvider: authProvider,
      );

      provider.onUsernameChanged('ab');
      await Future.delayed(const Duration(milliseconds: 700));

      expect(provider.usernameState, UsernameCheckState.invalidoFormato);
      expect(repository.chamadasVerificarUsername, 0);
    });

    test('indisponivel quando a API recusa', () async {
      final repository = _FakePerfilRepository(
        usernamesIndisponiveis: {'ocupado'},
      );
      final provider = EditarPerfilProvider(
        repository: repository,
        authProvider: authProvider,
      );

      provider.onUsernameChanged('ocupado');
      await Future.delayed(const Duration(milliseconds: 700));

      expect(provider.usernameState, UsernameCheckState.indisponivel);
      expect(provider.podeSalvar, isFalse);
    });

    test(
      'resetUsername volta ao original e cancela checagem pendente',
      () async {
        final repository = _FakePerfilRepository();
        final provider = EditarPerfilProvider(
          repository: repository,
          authProvider: authProvider,
        );

        provider.onUsernameChanged('novo1');
        provider.resetUsername();

        await Future.delayed(const Duration(milliseconds: 700));

        expect(provider.username, 'ana_original');
        expect(provider.usernameState, UsernameCheckState.atual);
        expect(repository.chamadasVerificarUsername, 0);
      },
    );
  });

  group('EditarPerfilProvider - salvar', () {
    test('salva com sucesso e propaga para AuthProvider', () async {
      final provider = EditarPerfilProvider(
        repository: _FakePerfilRepository(),
        authProvider: authProvider,
      );

      provider.onNomeChanged('Ana Editada');
      final ok = await provider.salvar();

      expect(ok, isTrue);
      expect(provider.status, SalvamentoStatus.salvo);
      expect(provider.temAlteracoes, isFalse);
      expect(authProvider.usuario?.nome, 'Ana Editada');
    });

    test('sobe foto e banner cortados como JPEG e limpa os bytes', () async {
      final repository = _FakePerfilRepository();
      final provider = EditarPerfilProvider(
        repository: repository,
        authProvider: authProvider,
      );
      final foto = Uint8List.fromList([1, 2, 3]);
      final banner = Uint8List.fromList([4, 5, 6]);

      provider.setFotoCortada(foto);
      provider.setBannerCortado(banner);
      final ok = await provider.salvar();

      expect(ok, isTrue);
      expect(repository.uploads, hasLength(2));
      expect(repository.uploads[0].tipo, 'foto');
      expect(repository.uploads[0].bytes, same(foto));
      expect(repository.uploads[0].filename, 'avatar.jpg');
      expect(repository.uploads[0].mimeType, 'image/jpeg');
      expect(repository.uploads[1].tipo, 'banner');
      expect(repository.uploads[1].bytes, same(banner));
      expect(repository.uploads[1].filename, 'banner.jpg');
      expect(repository.uploads[1].mimeType, 'image/jpeg');
      expect(
        repository.ultimosCamposEditados?['fotoPerfil'],
        'https://x/foto.png',
      );
      expect(
        repository.ultimosCamposEditados?['banner'],
        'https://x/banner.png',
      );
      expect(provider.novaFotoBytes, isNull);
      expect(provider.novoBannerBytes, isNull);
      expect(provider.temAlteracoes, isFalse);
    });

    test('hidrata fieldErrors quando o backend recusa a validacao', () async {
      final provider = EditarPerfilProvider(
        repository: _FakePerfilRepository(falharAoEditar: true),
        authProvider: authProvider,
      );

      provider.onNomeChanged('Ana Editada');
      final ok = await provider.salvar();

      expect(ok, isFalse);
      expect(provider.status, SalvamentoStatus.erro);
      expect(provider.fieldErrors['nome'], isNotNull);
    });

    test('podeSalvar false quando nome tem menos de 2 caracteres', () {
      final provider = EditarPerfilProvider(
        repository: _FakePerfilRepository(),
        authProvider: authProvider,
      );

      provider.onNomeChanged('A');
      expect(provider.podeSalvar, isFalse);
    });
  });
}
