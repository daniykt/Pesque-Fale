import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/domain/usuario.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/perfil_exceptions.dart';
import '../data/perfil_repository.dart';
import '../domain/username_check_state.dart';

enum SalvamentoStatus { idle, salvando, salvo, erro }

/// Provider escopado à tela de edição de perfil (não é global — criado no
/// build de `EditarPerfilPage`).
class EditarPerfilProvider extends ChangeNotifier {
  EditarPerfilProvider({required this.repository, required this.authProvider}) {
    _hidratarDoUsuarioLogado();
  }

  final PerfilRepository repository;
  final AuthProvider authProvider;

  static final _usernameRegex = RegExp(r'^[a-zA-Z0-9_.]{3,20}$');
  static const _debounceDuration = Duration(milliseconds: 500);
  static const _tamanhoMaximoBytes = 5 * 1024 * 1024;
  static const _formatosAceitos = {'jpg', 'jpeg', 'png', 'webp'};

  // ── Estado dos campos (editáveis) ──
  String nome = '';
  String bio = '';
  String localizacao = '';
  String username = '';
  String? novaFotoPath;
  String? novoBannerPath;

  // ── Estado original (dirty tracking e reset) ──
  late String _nomeOriginal;
  late String _bioOriginal;
  late String _localizacaoOriginal;
  late String _usernameOriginal;

  UsernameCheckState _usernameState = UsernameCheckState.idle;
  Timer? _debounceTimer;
  int _usernameCheckSeq = 0;

  SalvamentoStatus _status = SalvamentoStatus.idle;
  String? _errorMessage;
  Map<String, String> _fieldErrors = const {};

  // ── Getters derivados ──
  UsernameCheckState get usernameState => _usernameState;
  SalvamentoStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Map<String, String> get fieldErrors => _fieldErrors;

  bool get temAlteracoes =>
      nome != _nomeOriginal ||
      bio != _bioOriginal ||
      localizacao != _localizacaoOriginal ||
      username != _usernameOriginal ||
      novaFotoPath != null ||
      novoBannerPath != null;

  bool get podeSalvar =>
      nome.trim().length >= 2 &&
      _usernameValido() &&
      _status != SalvamentoStatus.salvando;

  void _hidratarDoUsuarioLogado() {
    final usuario = authProvider.usuario;
    nome = usuario?.nome ?? '';
    bio = usuario?.bio ?? '';
    localizacao = usuario?.localizacao ?? '';
    username = usuario?.username ?? '';
    _nomeOriginal = nome;
    _bioOriginal = bio;
    _localizacaoOriginal = localizacao;
    _usernameOriginal = username;
    _usernameState = UsernameCheckState.atual;
  }

  bool _usernameValido() {
    if (username == _usernameOriginal) return true;
    if (!_usernameRegex.hasMatch(username)) return false;
    return _usernameState == UsernameCheckState.disponivel;
  }

  void onNomeChanged(String valor) {
    nome = valor;
    notifyListeners();
  }

  void onBioChanged(String valor) {
    bio = valor;
    notifyListeners();
  }

  void onLocalizacaoChanged(String valor) {
    localizacao = valor;
    notifyListeners();
  }

  void onUsernameChanged(String valor) {
    username = valor;
    _debounceTimer?.cancel();

    if (username == _usernameOriginal) {
      _usernameState = UsernameCheckState.atual;
      notifyListeners();
      return;
    }

    if (!_usernameRegex.hasMatch(username)) {
      _usernameState = UsernameCheckState.invalidoFormato;
      notifyListeners();
      return;
    }

    _usernameState = UsernameCheckState.validating;
    notifyListeners();

    final seq = ++_usernameCheckSeq;
    _debounceTimer = Timer(
      _debounceDuration,
      () => _verificarUsername(username, seq),
    );
  }

  Future<void> _verificarUsername(String valor, int seq) async {
    try {
      final disponivel = await repository.verificarUsername(valor);
      if (seq != _usernameCheckSeq) return;
      _usernameState = disponivel
          ? UsernameCheckState.disponivel
          : UsernameCheckState.indisponivel;
    } on PerfilException {
      if (seq != _usernameCheckSeq) return;
      _usernameState = UsernameCheckState.indisponivel;
    }
    notifyListeners();
  }

  void resetUsername() {
    _debounceTimer?.cancel();
    username = _usernameOriginal;
    _usernameState = UsernameCheckState.atual;
    notifyListeners();
  }

  Future<bool> escolherFoto() => _escolherImagem(banner: false);

  Future<bool> escolherBanner() => _escolherImagem(banner: true);

  Future<bool> _escolherImagem({required bool banner}) async {
    final XFile? arquivo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (arquivo == null) return false;

    final extensao = arquivo.path.split('.').last.toLowerCase();
    if (!_formatosAceitos.contains(extensao)) {
      _errorMessage = const FormatoInvalidoException().message;
      notifyListeners();
      return false;
    }

    final tamanho = await arquivo.length();
    if (tamanho > _tamanhoMaximoBytes) {
      _errorMessage = const FotoMuitoGrandeException().message;
      notifyListeners();
      return false;
    }

    if (banner) {
      novoBannerPath = arquivo.path;
    } else {
      novaFotoPath = arquivo.path;
    }
    notifyListeners();
    return true;
  }

  Future<bool> salvar() async {
    if (!podeSalvar) return false;

    _status = SalvamentoStatus.salvando;
    _errorMessage = null;
    _fieldErrors = const {};
    notifyListeners();

    try {
      final campos = <String, dynamic>{};
      if (nome != _nomeOriginal) campos['nome'] = nome;
      if (bio != _bioOriginal) campos['bio'] = bio;
      if (localizacao != _localizacaoOriginal) {
        campos['localizacao'] = localizacao;
      }
      if (username != _usernameOriginal) campos['username'] = username;

      if (novaFotoPath != null) {
        campos['fotoPerfil'] = await repository.atualizarFoto(
          File(novaFotoPath!),
        );
      }
      if (novoBannerPath != null) {
        campos['banner'] = await repository.atualizarBanner(
          File(novoBannerPath!),
        );
      }

      final atualizado = campos.isEmpty
          ? authProvider.usuario!
          : await repository.editarPerfil(campos);

      authProvider.atualizarUsuario(atualizado);
      _sincronizarOriginais(atualizado);

      _status = SalvamentoStatus.salvo;
      notifyListeners();
      return true;
    } on PerfilValidationException catch (e) {
      _fieldErrors = e.fieldErrors;
      _errorMessage = e.message;
      _status = SalvamentoStatus.erro;
      notifyListeners();
      return false;
    } on PerfilException catch (e) {
      _errorMessage = e.message;
      _status = SalvamentoStatus.erro;
      notifyListeners();
      return false;
    }
  }

  void _sincronizarOriginais(Usuario atualizado) {
    nome = atualizado.nome;
    bio = atualizado.bio ?? '';
    localizacao = atualizado.localizacao ?? '';
    username = atualizado.username ?? '';
    _nomeOriginal = nome;
    _bioOriginal = bio;
    _localizacaoOriginal = localizacao;
    _usernameOriginal = username;
    _usernameState = UsernameCheckState.atual;
    novaFotoPath = null;
    novoBannerPath = null;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
