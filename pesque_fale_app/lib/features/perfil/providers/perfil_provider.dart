import 'package:flutter/foundation.dart';

import '../../auth/domain/usuario.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/perfil_exceptions.dart';
import '../data/perfil_repository.dart';
import '../domain/publicacao.dart';

enum PerfilStatus { idle, loading, success, error }

class PerfilProvider extends ChangeNotifier {
  PerfilProvider({required this.repository, required this.authProvider});

  final PerfilRepository repository;
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

  bool get chatLiberado =>
      !isOwnProfile && (_isFollowing || _seguidoPeloOutro);

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

  /// Gera/identifica o chat com o dono deste perfil (compatibilidade com o
  /// formato de chatId `[uid1, uid2]..sort().join('_')`).
  String abrirChat() {
    final meuId = authProvider.usuario?.id ?? '';
    final outroId = _perfil?.id ?? '';
    final ids = [meuId, outroId]..sort();
    return ids.join('_');
  }
}
