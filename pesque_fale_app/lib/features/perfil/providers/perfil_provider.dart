import 'package:flutter/foundation.dart';

import '../../../core/realtime/realtime_manager.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/perfil_exceptions.dart';
import '../data/perfil_repository.dart';
import '../domain/publicacao.dart';

enum PerfilStatus { idle, loading, success, error }

class PerfilProvider extends ChangeNotifier {
  PerfilProvider({
    required this.repository,
    required this.authProvider,
    this.realtime,
  }) {
    authProvider.addListener(_onAuthChanged);
    realtime?.subscribe('seguidor_adicionado', _onSeguidorMudou);
    realtime?.subscribe('seguidor_removido', _onSeguidorMudou);
  }

  final PerfilRepository repository;

  /// Só o provider global (aba Perfil do próprio usuário) recebe o manager.
  /// O da rota `/perfil` (perfil de outro) não passa e fica sem realtime.
  final RealtimeManager? realtime;
  AuthProvider authProvider;

  PerfilStatus _status = PerfilStatus.idle;
  String? _errorMessage;
  Usuario? _perfil;
  List<Publicacao> _publicacoes = const [];
  bool _isFollowing = false;
  bool _seguidoPeloOutro = false;

  PerfilStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Usuario? get perfil => _perfil;
  List<Publicacao> get publicacoes => _publicacoes;
  bool get isFollowing => _isFollowing;

  bool get isOwnProfile =>
      _perfil != null && _perfil!.id == authProvider.usuario?.id;

  bool get chatLiberado => !isOwnProfile && (_isFollowing && _seguidoPeloOutro);

  /// Follow unilateral: eu sigo, mas o outro não me segue de volta. Nesse
  /// estado o chat fica bloqueado e a tela explica o porquê.
  bool get mostrarHintMutualFollow =>
      !isOwnProfile && _isFollowing && !_seguidoPeloOutro;

  /// O outro me segue e eu ainda não sigo: o CTA oferece "Seguir de volta".
  bool get podeSeguirDeVolta =>
      !isOwnProfile && !_isFollowing && _seguidoPeloOutro;

  int get totalPublicacoes => _publicacoes.length;

  Future<void> carregarPerfil(String id) async {
    _status = PerfilStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final meuId = authProvider.usuario?.id ?? '';
      final completo = await repository.buscarPerfil(id, meuId: meuId);
      _perfil = completo.usuario;
      _publicacoes = completo.publicacoes;
      _isFollowing = completo.isFollowing;
      _seguidoPeloOutro = completo.seguidoPeloOutro;
      _status = PerfilStatus.success;
    } on PerfilException catch (e) {
      _errorMessage = e.message;
      _status = PerfilStatus.error;
    }
    notifyListeners();
  }

  Future<bool> seguir() async {
    if (_perfil == null || isOwnProfile) return false;

    final perfilAnterior = _perfil!;
    final seguindoAnterior = _isFollowing;

    _isFollowing = true;
    _perfil = perfilAnterior.copyWith(
      seguidores: perfilAnterior.seguidores + 1,
    );
    notifyListeners();

    try {
      await repository.seguir(perfilAnterior.id);
      return true;
    } on PerfilException catch (e) {
      _isFollowing = seguindoAnterior;
      _perfil = perfilAnterior;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deixarDeSeguir() async {
    if (_perfil == null || isOwnProfile) return false;

    final perfilAnterior = _perfil!;
    final seguindoAnterior = _isFollowing;

    _isFollowing = false;
    _perfil = perfilAnterior.copyWith(
      seguidores: perfilAnterior.seguidores > 0
          ? perfilAnterior.seguidores - 1
          : 0,
    );
    notifyListeners();

    try {
      await repository.deixarDeSeguir(perfilAnterior.id);
      return true;
    } on PerfilException catch (e) {
      _isFollowing = seguindoAnterior;
      _perfil = perfilAnterior;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> atualizarFoto(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async {
    try {
      final url = await repository.atualizarFoto(
        bytes,
        filename: filename,
        mimeType: mimeType,
      );
      _perfil = _perfil?.copyWith(fotoPerfil: url);
      notifyListeners();
      return true;
    } on PerfilException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> atualizarBanner(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async {
    try {
      final url = await repository.atualizarBanner(
        bytes,
        filename: filename,
        mimeType: mimeType,
      );
      _perfil = _perfil?.copyWith(banner: url);
      notifyListeners();
      return true;
    } on PerfilException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Gera/identifica o chat com o dono deste perfil (compatibilidade com o
  /// formato de chatId `[uid1, uid2]..sort().join('_')`).
  String abrirChat() {
    final meuId = authProvider.usuario?.id ?? '';
    final outroId = _perfil?.id ?? '';
    final ids = [meuId, outroId]..sort();
    return ids.join('_');
  }

  /// Reassocia o listener quando o `ProxyProvider` recria/reatribui o
  /// `AuthProvider` (evita listener órfão apontando para instância antiga).
  void rebindAuth(AuthProvider novo) {
    if (identical(novo, authProvider)) return;
    authProvider.removeListener(_onAuthChanged);
    authProvider = novo;
    authProvider.addListener(_onAuthChanged);
  }

  /// Espelha localmente o usuário do `AuthProvider` quando ele muda enquanto
  /// estamos visualizando o próprio perfil — sem refetch de rede, o dado já
  /// vem pronto de `EditarPerfilProvider.salvar()`.
  void _onAuthChanged() {
    final usuarioLogado = authProvider.usuario;
    if (usuarioLogado == null || _perfil == null) return;
    if (_perfil!.id != usuarioLogado.id) return;
    if (identical(_perfil, usuarioLogado)) return;
    _perfil = usuarioLogado;
    notifyListeners();
  }

  /// `seguidor_adicionado` e `seguidor_removido` trazem o total contado no
  /// banco, então ele vale mais que o update otimista: se bater, é no-op;
  /// se divergir (ex.: follows simultâneos), corrige.
  void _onSeguidorMudou(dynamic payload) {
    if (payload is! Map) return;
    if (!isOwnProfile) return;
    final total = payload['totalSeguidores'];
    if (total is! int) return;
    if (total == _perfil!.seguidores) return;
    _perfil = _perfil!.copyWith(seguidores: total);
    notifyListeners();
  }

  @override
  void dispose() {
    realtime?.unsubscribe('seguidor_adicionado', _onSeguidorMudou);
    realtime?.unsubscribe('seguidor_removido', _onSeguidorMudou);
    authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }
}
