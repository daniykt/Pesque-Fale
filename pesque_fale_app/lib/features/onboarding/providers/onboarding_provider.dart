import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../auth/providers/auth_provider.dart';
import '../../perfil/data/perfil_exceptions.dart';
import '../../perfil/data/perfil_repository.dart';
import '../domain/onboarding_etapa.dart';
import '../domain/username_onboarding_state.dart';

/// Provider único do wizard de onboarding (não é global — criado no build
/// da rota `/onboarding`).
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider({
    required this.perfilRepository,
    required this.authProvider,
  }) {
    _hidratar();
  }

  final PerfilRepository perfilRepository;
  final AuthProvider authProvider;

  static final _usernameRegex = RegExp(r'^[a-zA-Z0-9_.]{3,20}$');
  static const _debounceDuration = Duration(milliseconds: 500);

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

  /// Sobe a foto de perfil já recortada (JPEG da CropImagemPage).
  Future<bool> enviarFotoCortada(Uint8List bytes) =>
      _enviarImagem(bytes, banner: false);

  /// Sobe a capa já recortada (JPEG da CropImagemPage).
  Future<bool> enviarBannerCortado(Uint8List bytes) =>
      _enviarImagem(bytes, banner: true);

  Future<bool> _enviarImagem(Uint8List bytes, {required bool banner}) async {
    errorMessage = null;
    if (banner) {
      uploadingCapa = true;
    } else {
      uploadingFoto = true;
    }
    notifyListeners();

    try {
      // O crop sempre gera JPEG, então nome e tipo são fixos.
      final url = banner
          ? await perfilRepository.atualizarBanner(
              bytes,
              filename: 'banner.jpg',
              mimeType: 'image/jpeg',
            )
          : await perfilRepository.atualizarFoto(
              bytes,
              filename: 'avatar.jpg',
              mimeType: 'image/jpeg',
            );
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
        'onboardingConcluido': true,
      };

      final usuarioAtualizado = await perfilRepository.editarPerfil(campos);

      authProvider.atualizarUsuario(usuarioAtualizado);

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
