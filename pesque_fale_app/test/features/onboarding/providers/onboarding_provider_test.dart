import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/onboarding/domain/onboarding_etapa.dart';
import 'package:pesque_fale_app/features/onboarding/domain/onboarding_status_storage.dart';
import 'package:pesque_fale_app/features/onboarding/domain/username_onboarding_state.dart';
import 'package:pesque_fale_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_exceptions.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository.dart';
import 'package:pesque_fale_app/features/perfil/domain/perfil_completo.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.nomeInicial = 'Ana'});

  final String nomeInicial;

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
    return AuthResult(
      accessToken: 'token',
      usuario: Usuario(
        id: 'user-1',
        nome: nomeInicial,
        email: 'ana@teste.com',
        onboardingConcluido: false,
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
  Map<String, dynamic>? ultimosCamposEditados;

  @override
  Future<PerfilCompleto> buscarPerfil(
    String id, {
    required String meuId,
  }) async => throw UnimplementedError();

  @override
  Future<void> seguir(String id) async {}

  @override
  Future<void> deixarDeSeguir(String id) async {}

  @override
  Future<String> atualizarFoto(File arquivo) async =>
      'https://x.com/foto-nova.png';

  @override
  Future<String> atualizarBanner(File arquivo) async =>
      'https://x.com/capa-nova.png';

  @override
  Future<Usuario> editarPerfil(Map<String, dynamic> camposAlterados) async {
    ultimosCamposEditados = camposAlterados;
    if (falharAoEditar) {
      throw PerfilValidationException({'nome': 'Nome inválido.'});
    }
    return Usuario(
      id: 'user-1',
      nome: camposAlterados['nome'] as String? ?? 'Ana',
      email: 'ana@teste.com',
      username: camposAlterados['username'] as String?,
      bio: camposAlterados['bio'] as String?,
      localizacao: camposAlterados['localizacao'] as String?,
      onboardingConcluido: true,
    );
  }

  @override
  Future<bool> verificarUsername(String username) async {
    chamadasVerificarUsername++;
    await Future.delayed(const Duration(milliseconds: 50));
    return !usernamesIndisponiveis.contains(username);
  }
}

class _FakeStatusStorage extends OnboardingStatusStorage {
  final Map<String, bool> _dados = {};

  @override
  Future<bool> isConcluido(String userId) async => _dados[userId] ?? false;

  @override
  Future<void> marcarConcluido(String userId) async {
    _dados[userId] = true;
  }

  @override
  Future<void> limpar(String userId) async {
    _dados.remove(userId);
  }
}

/// Fake do canal de plataforma do image_picker, devolvendo um caminho de
/// arquivo configurável (ou nenhum, simulando cancelamento).
class _FakeImagePickerChannel {
  _FakeImagePickerChannel() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, _handle);
  }

  static const _channel = MethodChannel('plugins.flutter.io/image_picker');

  String? proximoCaminho;

  Future<dynamic> _handle(MethodCall call) async {
    if (call.method == 'pickImage') return proximoCaminho;
    return null;
  }
}

Future<String> _criarArquivoTemporario({
  required String extensao,
  int tamanhoBytes = 100,
}) async {
  final dir = await Directory.systemTemp.createTemp('onboarding_test_');
  final arquivo = File('${dir.path}/imagem.$extensao');
  await arquivo.writeAsBytes(List.filled(tamanhoBytes, 0));
  return arquivo.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthProvider authProvider;
  late _FakePerfilRepository perfilRepository;
  late _FakeStatusStorage statusStorage;
  late _FakeImagePickerChannel imagePickerChannel;

  Future<OnboardingProvider> montarProvider({
    String nomeInicial = 'Ana',
    Set<String> usernamesIndisponiveis = const {},
    bool falharAoEditar = false,
  }) async {
    authProvider = AuthProvider(
      repository: _FakeAuthRepository(nomeInicial: nomeInicial),
    );
    await authProvider.login(email: 'ana@teste.com', senha: '123456');

    perfilRepository = _FakePerfilRepository(
      usernamesIndisponiveis: usernamesIndisponiveis,
      falharAoEditar: falharAoEditar,
    );
    statusStorage = _FakeStatusStorage();

    return OnboardingProvider(
      perfilRepository: perfilRepository,
      authProvider: authProvider,
      statusStorage: statusStorage,
    );
  }

  setUp(() {
    imagePickerChannel = _FakeImagePickerChannel();
  });

  group('OnboardingProvider - estado inicial', () {
    test('etapa inicial e boasVindas e nome hidrata do usuario logado', () async {
      final provider = await montarProvider(nomeInicial: 'Ana Pescadora');

      expect(provider.etapaAtual, OnboardingEtapa.boasVindas);
      expect(provider.nome, 'Ana Pescadora');
    });
  });

  group('OnboardingProvider - navegacao', () {
    test('avancar progride pelo enum na ordem certa', () async {
      final provider = await montarProvider();

      for (final etapa in OnboardingEtapa.values.sublist(
        1,
        OnboardingEtapa.values.length,
      )) {
        provider.avancar();
        expect(provider.etapaAtual, etapa);
      }

      // Na ultima etapa, avancar novamente nao deve estourar o enum.
      provider.avancar();
      expect(provider.etapaAtual, OnboardingEtapa.sucesso);
    });

    test('voltar retrocede mas trava em boasVindas', () async {
      final provider = await montarProvider();

      provider.avancar();
      provider.avancar();
      expect(provider.etapaAtual, OnboardingEtapa.nomeLocalizacao);

      provider.voltar();
      expect(provider.etapaAtual, OnboardingEtapa.fotoPerfil);
      provider.voltar();
      expect(provider.etapaAtual, OnboardingEtapa.boasVindas);

      provider.voltar();
      expect(provider.etapaAtual, OnboardingEtapa.boasVindas);
    });

    test('pularEtapa avanca quando etapa permite pular', () async {
      final provider = await montarProvider();

      provider.avancar();
      expect(provider.etapaAtual, OnboardingEtapa.fotoPerfil);

      provider.pularEtapa();
      expect(provider.etapaAtual, OnboardingEtapa.nomeLocalizacao);
    });

    test('pularEtapa e no-op em etapas que nao permitem pular', () async {
      final provider = await montarProvider();

      expect(provider.etapaAtual, OnboardingEtapa.boasVindas);
      provider.pularEtapa();
      expect(provider.etapaAtual, OnboardingEtapa.boasVindas);

      provider.avancar();
      provider.avancar();
      provider.avancar();
      expect(provider.etapaAtual, OnboardingEtapa.username);
      provider.pularEtapa();
      expect(provider.etapaAtual, OnboardingEtapa.username);
    });
  });

  group('OnboardingProvider - username', () {
    test('onUsernameChanged com valor vazio volta para idle', () async {
      final provider = await montarProvider();

      provider.onUsernameChanged('algo');
      provider.onUsernameChanged('');

      expect(provider.usernameOnboardingState, UsernameOnboardingState.idle);
    });

    test('onUsernameChanged com formato invalido', () async {
      final provider = await montarProvider();

      provider.onUsernameChanged('ab');
      await Future.delayed(const Duration(milliseconds: 700));

      expect(
        provider.usernameOnboardingState,
        UsernameOnboardingState.invalidoFormato,
      );
      expect(perfilRepository.chamadasVerificarUsername, 0);
    });

    test(
      'onUsernameChanged com valor valido transita por validating e chega em disponivel',
      () async {
        final provider = await montarProvider();

        provider.onUsernameChanged('pescador123');
        expect(
          provider.usernameOnboardingState,
          UsernameOnboardingState.validating,
        );

        await Future.delayed(const Duration(milliseconds: 700));

        expect(
          provider.usernameOnboardingState,
          UsernameOnboardingState.disponivel,
        );
      },
    );

    test('podeAvancarEtapaUsername e false ate ficar disponivel', () async {
      final provider = await montarProvider(
        usernamesIndisponiveis: {'ocupado'},
      );

      expect(provider.podeAvancarEtapaUsername, isFalse);

      provider.onUsernameChanged('ocupado');
      await Future.delayed(const Duration(milliseconds: 700));
      expect(provider.usernameOnboardingState, UsernameOnboardingState.indisponivel);
      expect(provider.podeAvancarEtapaUsername, isFalse);

      provider.onUsernameChanged('livre123');
      await Future.delayed(const Duration(milliseconds: 700));
      expect(provider.usernameOnboardingState, UsernameOnboardingState.disponivel);
      expect(provider.podeAvancarEtapaUsername, isTrue);
    });
  });

  group('OnboardingProvider - podeAvancarEtapaNomeLocalizacao', () {
    test('respeita minimo de 2 caracteres no nome', () async {
      final provider = await montarProvider(nomeInicial: '');

      provider.onNomeChanged('A');
      expect(provider.podeAvancarEtapaNomeLocalizacao, isFalse);

      provider.onNomeChanged('AB');
      expect(provider.podeAvancarEtapaNomeLocalizacao, isTrue);
    });
  });

  group('OnboardingProvider - upload de imagens', () {
    test('escolherEEnviarFoto em sucesso preenche a url e desliga o loading', () async {
      final provider = await montarProvider();
      imagePickerChannel.proximoCaminho = await _criarArquivoTemporario(
        extensao: 'jpg',
      );

      final ok = await provider.escolherEEnviarFoto();

      expect(ok, isTrue);
      expect(provider.fotoPerfilUrl, 'https://x.com/foto-nova.png');
      expect(provider.uploadingFoto, isFalse);
    });

    test('escolherEEnviarFoto em erro de formato preenche errorMessage', () async {
      final provider = await montarProvider();
      imagePickerChannel.proximoCaminho = await _criarArquivoTemporario(
        extensao: 'txt',
      );

      final ok = await provider.escolherEEnviarFoto();

      expect(ok, isFalse);
      expect(provider.errorMessage, isNotNull);
      expect(provider.fotoPerfilUrl, isNull);
      expect(provider.uploadingFoto, isFalse);
    });
  });

  group('OnboardingProvider - concluir', () {
    test('em sucesso envia campos preenchidos, marca storage e avanca para sucesso', () async {
      final provider = await montarProvider();
      provider.onNomeChanged('Ana Editada');
      provider.onLocalizacaoChanged('Floripa');
      provider.onBioChanged('Bio nova');
      provider.username = 'ana_pesca';

      final ok = await provider.concluir(userId: 'user-1');

      expect(ok, isTrue);
      expect(provider.etapaAtual, OnboardingEtapa.sucesso);
      expect(provider.concluindo, isFalse);
      expect(perfilRepository.ultimosCamposEditados?['nome'], 'Ana Editada');
      expect(
        perfilRepository.ultimosCamposEditados?['localizacao'],
        'Floripa',
      );
      expect(perfilRepository.ultimosCamposEditados?['bio'], 'Bio nova');
      expect(perfilRepository.ultimosCamposEditados?['username'], 'ana_pesca');
      expect(authProvider.usuario?.nome, 'Ana Editada');
      expect(await statusStorage.isConcluido('user-1'), isTrue);
    });

    test('em erro de validacao mantem a etapa e preenche errorMessage', () async {
      final provider = await montarProvider(falharAoEditar: true);
      provider.onNomeChanged('Ana');
      provider.username = 'ana_pesca';

      final etapaAntes = provider.etapaAtual;
      final ok = await provider.concluir(userId: 'user-1');

      expect(ok, isFalse);
      expect(provider.errorMessage, isNotNull);
      expect(provider.etapaAtual, etapaAntes);
      expect(await statusStorage.isConcluido('user-1'), isFalse);
    });
  });
}
