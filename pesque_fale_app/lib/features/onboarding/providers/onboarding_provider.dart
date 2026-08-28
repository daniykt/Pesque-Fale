import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/providers/auth_provider.dart';
import '../../perfil/data/perfil_exceptions.dart';
import '../../perfil/data/perfil_repository.dart';
import '../domain/onboarding_etapa.dart';
import '../domain/onboarding_status_storage.dart';
import '../domain/username_onboarding_state.dart';

/// Provider único do wizard de onboarding (não é global — criado no build
/// da rota `/onboarding`).
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider({
    required this.perfilRepository,
    required this.authProvider,
    required this.statusStorage,
  }) {
    _hidratar();
  }

  final PerfilRepository perfilRepository;
  final AuthProvider authProvider;
  final OnboardingStatusStorage statusStorage;

  static final _usernameRegex = RegExp(r'^[a-zA-Z0-9_.]{3,20}$');
  static const _debounceDuration = Duration(milliseconds: 500);
  static const _tamanhoMaximoBytes = 5 * 1024 * 1024;
  static const _formatosAceitos = {'jpg', 'jpeg', 'png', 'webp'};

  // ── Estado das etapas ──
  OnboardingEtapa etapaAtual = OnboardingEtapa.boasVindas;

  // ── Estado dos campos ──
  String? fotoPerfilUrl;
  String? fotoCapaUrl;
  String nome = '';
  String localizacao = '';
  String username = '';
  String bio = '';

  // ── Estado de upload ──
  bool uploadingFoto = false;
  bool uploadingCapa = false;

  // ── Estado de username ──
  UsernameOnboardingState _usernameState = UsernameOnboardingState.idle;
  Timer? _debounceTimer;
  int _usernameCheckSeq = 0;

  UsernameOnboardingState get usernameOnboardingState => _usernameState;

  // ── Estado de conclusão ──
  bool concluindo = false;
  String? errorMessage;

  void _hidratar() {
    final usuario = authProvider.usuario;
    nome = usuario?.nome ?? '';
  }

  bool get podeAvancarEtapaUsername =>
      _usernameState == UsernameOnboardingState.disponivel;

  bool get podeAvancarEtapaNomeLocalizacao => nome.trim().length >= 2;

  void avancar() {
    final proximoIndice = etapaAtual.index + 1;
    if (proximoIndice >= OnboardingEtapa.values.length) return;
    etapaAtual = OnboardingEtapa.values[proximoIndice];
    notifyListeners();
  }

  void voltar() {
    if (etapaAtual == OnboardingEtapa.boasVindas) return;
    final anteriorIndice = etapaAtual.index - 1;
    etapaAtual = OnboardingEtapa.values[anteriorIndice];
    notifyListeners();
  }

  void pularEtapa() {
    if (!etapaAtual.permitePular) return;
    avancar();
  }

  void onNomeChanged(String valor) {
    nome = valor;
    notifyListeners();
  }

  void onLocalizacaoChanged(String valor) {
    localizacao = valor;
    notifyListeners();
  }

  void onBioChanged(String valor) {
    bio = valor;
    notifyListeners();
  }

  void onUsernameChanged(String valor) {
    username = valor;
    _debounceTimer?.cancel();

    if (username.isEmpty) {
      _usernameState = UsernameOnboardingState.idle;
      notifyListeners();
      return;
    }

    if (!_usernameRegex.hasMatch(username)) {
      _usernameState = UsernameOnboardingState.invalidoFormato;
      notifyListeners();
      return;
    }

    _usernameState = UsernameOnboardingState.validating;
    notifyListeners();

    final seq = ++_usernameCheckSeq;
    _debounceTimer = Timer(
      _debounceDuration,
      () => _verificarUsername(username, seq),
    );
  }

  Future<void> _verificarUsername(String valor, int seq) async {
    try {
      final disponivel = await perfilRepository.verificarUsername(valor);
      if (seq != _usernameCheckSeq) return;
      _usernameState = disponivel
          ? UsernameOnboardingState.disponivel
          : UsernameOnboardingState.indisponivel;
    } on PerfilException {
      if (seq != _usernameCheckSeq) return;
      _usernameState = UsernameOnboardingState.indisponivel;
    }
    notifyListeners();
  }

  Future<bool> escolherEEnviarFoto() => _escolherEEnviarImagem(banner: false);

  Future<bool> escolherEEnviarCapa() => _escolherEEnviarImagem(banner: true);

  Future<bool> _escolherEEnviarImagem({required bool banner}) async {
    final XFile? arquivo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (arquivo == null) return false;

    final extensao = arquivo.path.split('.').last.toLowerCase();
    if (!_formatosAceitos.contains(extensao)) {
      errorMessage = const FormatoInvalidoException().message;
      notifyListeners();
      return false;
    }

    final tamanho = await arquivo.length();
    if (tamanho > _tamanhoMaximoBytes) {
      errorMessage = const FotoMuitoGrandeException().message;
      notifyListeners();
      return false;
    }

    if (banner) {
      uploadingCapa = true;
    } else {
      uploadingFoto = true;
    }
    notifyListeners();

    try {
      final url = banner
          ? await perfilRepository.atualizarBanner(File(arquivo.path))
          : await perfilRepository.atualizarFoto(File(arquivo.path));
      if (banner) {
        fotoCapaUrl = url;
      } else {
        fotoPerfilUrl = url;
      }
      return true;
    } on PerfilException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      if (banner) {
        uploadingCapa = false;
      } else {
        uploadingFoto = false;
      }
      notifyListeners();
    }
  }

  Future<bool> concluir({required String userId}) async {
    concluindo = true;
    errorMessage = null;
    notifyListeners();

    try {
      final campos = <String, dynamic>{
        'nome': nome,
        'username': username,
        if (localizacao.isNotEmpty) 'localizacao': localizacao,
        if (bio.isNotEmpty) 'bio': bio,
      };

      final usuarioAtualizado = await perfilRepository.editarPerfil(campos);

      authProvider.atualizarUsuario(usuarioAtualizado);
      await statusStorage.marcarConcluido(userId);

      etapaAtual = OnboardingEtapa.sucesso;
      return true;
    } on PerfilException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      concluindo = false;
      notifyListeners();
    }
  }

  void limparErro() {
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
