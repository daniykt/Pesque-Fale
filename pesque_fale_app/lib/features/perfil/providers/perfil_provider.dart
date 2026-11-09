import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/realtime/realtime_manager.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/perfil_exceptions.dart';
import '../data/perfil_repository.dart';
import '../../feed/domain/publicacao.dart';
import '../../feed/providers/publicacoes_store.dart';

enum PerfilStatus { idle, loading, success, error }

class PerfilProvider extends ChangeNotifier {
  PerfilProvider({
    required this.repository,
    required this.authProvider,
    required this.store,
    this.realtime,
  }) {
    authProvider.addListener(_onAuthChanged);
    store.addListener(_onStoreMudou);
    realtime?.subscribe('seguidor_adicionado', _onSeguidorMudou);
    realtime?.subscribe('seguidor_removido', _onSeguidorMudou);
  }

  final PerfilRepository repository;
  final PublicacoesStore store;

  /// Só o provider global (aba Perfil do próprio usuário) recebe o manager.
  /// O da rota `/perfil` (perfil de outro) não passa e fica sem realtime.
  final RealtimeManager? realtime;
  AuthProvider authProvider;

  PerfilStatus _status = PerfilStatus.idle;
  String? _errorMessage;
  Usuario? _perfil;
  final List<String> _idsPublicacoes = [];
  List<Publicacao>? _cachePublicacoes;
  bool _isFollowing = false;
  bool _seguidoPeloOutro = false;
  int _totalPublicacoes = 0;

  PerfilStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Usuario? get perfil => _perfil;
  List<Publicacao> get publicacoes =>
      _cachePublicacoes ??= List.unmodifiable(store.resolver(_idsPublicacoes));
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

  /// Total de publicações do perfil, não só as da primeira página carregada.
  /// Vem da API e acompanha as criadas e excluídas no app (via store).
  int get totalPublicacoes => _totalPublicacoes;

  Future<void> carregarPerfil(String id) async {
    _status = PerfilStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final meuId = authProvider.usuario?.id ?? '';
      final completo = await repository.buscarPerfil(id, meuId: meuId);
      _perfil = completo.usuario;
      _idsPublicacoes
        ..clear()
        ..addAll(completo.publicacoes.map((p) => p.id));
      _cachePublicacoes = null;
      _totalPublicacoes =
          completo.totalPublicacoes ?? completo.publicacoes.length;
      _inserirNoStoreComDono(completo.usuario, completo.publicacoes);
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

  // TODO(#267): remover quando GET /usuarios/:id/publicacoes devolver autor e
  // jaCurtiu; aí basta store.upsertTodos(publicacoes).
  void _inserirNoStoreComDono(Usuario dono, List<Publicacao> publicacoes) {
    store.inserirSeAusente(
      publicacoes.map(
        (p) => Publicacao(
          id: p.id,
          autorId: p.autorId,
          autorNome: p.autorNome.isEmpty ? dono.nome : p.autorNome,
          autorUsername: p.autorUsername ?? dono.username,
          autorFoto: p.autorFoto ?? dono.fotoPerfil,
          pontoId: p.pontoId,
          descricao: p.descricao,
          imagemUrl: p.imagemUrl,
          localTexto: p.localTexto,
          avaliacaoNota: p.avaliacaoNota,
          tags: p.tags,
          curtidasCount: p.curtidasCount,
          comentariosCount: p.comentariosCount,
          jaCurtiu: p.jaCurtiu,
          criadoEm: p.criadoEm,
          atualizadoEm: p.atualizadoEm,
        ),
      ),
    );
  }

  void _onStoreMudou() {
    final antes = _idsPublicacoes.length;
    _idsPublicacoes.removeWhere(store.foiRemovida);
    final removidas = antes - _idsPublicacoes.length;

    final dono = _perfil?.id;
    final novas = dono == null ? const <String>[] : _novasDoDono(dono);
    _idsPublicacoes.insertAll(0, novas);

    // Só conta o que entrou ou saiu desta lista. Exclusão de uma publicação
    // que não está na página carregada só aparece ao recarregar o perfil.
    _totalPublicacoes = max(0, _totalPublicacoes - removidas + novas.length);
    _cachePublicacoes = null;
    notifyListeners();
  }

  List<String> _novasDoDono(String dono) {
    final atuais = _idsPublicacoes.toSet();
    final conhecidas = store.resolver(_idsPublicacoes);
    final maisRecente = conhecidas.isEmpty
        ? null
        : conhecidas
              .map((p) => p.criadoEm)
              .reduce((a, b) => a.isAfter(b) ? a : b);
    final novas =
        store
            .publicacoesDoAutor(dono)
            .where(
              (p) =>
                  !atuais.contains(p.id) &&
                  (maisRecente == null || p.criadoEm.isAfter(maisRecente)),
            )
            .toList()
          ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    return novas.map((p) => p.id).toList();
  }

  @override
  void dispose() {
    store.removeListener(_onStoreMudou);
    realtime?.unsubscribe('seguidor_adicionado', _onSeguidorMudou);
    realtime?.unsubscribe('seguidor_removido', _onSeguidorMudou);
    authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }
}
