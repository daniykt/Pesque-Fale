import 'package:flutter/foundation.dart';

import '../data/perfil_api_client.dart';
import '../data/perfil_exceptions.dart';
import '../data/perfil_repository.dart';

enum TipoRelacionamento { seguidores, seguindo }

enum ListaRelacionamentosStatus { idle, loading, success, error }

/// Gerencia a lista paginada de seguidores/seguindo exibida no bottom sheet
/// aberto pelos contadores da tela de Perfil.
///
/// A classe mantém um estado de ids em processamento para desabilitar o botão
/// de follow/unfollow enquanto a request está em voo e evitar double-tap. O
/// update é otimista: o estado local muda antes da chamada, e qualquer falha
/// faz rollback + propaga a mensagem via [ultimoErroAcao].
class ListaRelacionamentosProvider extends ChangeNotifier {
  ListaRelacionamentosProvider({
    required this.repository,
    required this.perfilId,
    required this.tipo,
    required this.meuId,
    this.porPagina = 20,
  });

  final PerfilRepository repository;
  final String perfilId;
  final TipoRelacionamento tipo;
  final String meuId;
  final int porPagina;

  ListaRelacionamentosStatus _status = ListaRelacionamentosStatus.idle;
  final List<UsuarioResumido> _itens = [];
  int _pagina = 0;
  int _total = 0;
  bool _carregandoMais = false;
  String? _errorMessage;

  /// Ação (seguir/deixar de seguir) em voo pra cada id. Evita duplo-clique e
  /// permite spinner inline por item.
  final Set<String> _idsEmProcessamento = {};
  String? _ultimoErroAcao;

  ListaRelacionamentosStatus get status => _status;
  List<UsuarioResumido> get itens => List.unmodifiable(_itens);
  int get total => _total;
  bool get carregandoMais => _carregandoMais;
  bool get hasMore => _itens.length < _total;
  String? get errorMessage => _errorMessage;

  bool emProcessamento(String id) => _idsEmProcessamento.contains(id);

  /// Última falha de follow/unfollow, consumida uma única vez por quem precisa
  /// exibir SnackBar. Após ler, chame [limparUltimoErroAcao].
  String? get ultimoErroAcao => _ultimoErroAcao;
  void limparUltimoErroAcao() => _ultimoErroAcao = null;

  Future<void> carregarInicial() async {
    if (_status == ListaRelacionamentosStatus.loading) return;
    _status = ListaRelacionamentosStatus.loading;
    _errorMessage = null;
    _itens.clear();
    _pagina = 0;
    _total = 0;
    notifyListeners();

    try {
      final paginada = await _buscar(pagina: 1);
      _itens.addAll(paginada.itens);
      _pagina = 1;
      _total = paginada.total;
      _status = ListaRelacionamentosStatus.success;
    } on PerfilException catch (e) {
      _errorMessage = e.message;
      _status = ListaRelacionamentosStatus.error;
    }
    notifyListeners();
  }

  Future<void> carregarMais() async {
    if (_carregandoMais ||
        _status != ListaRelacionamentosStatus.success ||
        !hasMore) {
      return;
    }
    _carregandoMais = true;
    notifyListeners();

    try {
      final paginada = await _buscar(pagina: _pagina + 1);
      _itens.addAll(paginada.itens);
      _pagina = _pagina + 1;
      _total = paginada.total;
    } on PerfilException catch (e) {
      _errorMessage = e.message;
    } finally {
      _carregandoMais = false;
      notifyListeners();
    }
  }

  Future<void> seguir(String itemId) =>
      _mudarRelacao(itemId, seguir: true);

  Future<void> deixarDeSeguir(String itemId) =>
      _mudarRelacao(itemId, seguir: false);

  Future<void> _mudarRelacao(String itemId, {required bool seguir}) async {
    if (_idsEmProcessamento.contains(itemId)) return;
    if (itemId == meuId) return;

    final index = _itens.indexWhere((u) => u.id == itemId);
    if (index == -1) return;

    final anterior = _itens[index];
    _itens[index] = anterior.copyWith(souSeguidor: seguir);
    _idsEmProcessamento.add(itemId);
    notifyListeners();

    try {
      if (seguir) {
        await repository.seguir(itemId);
      } else {
        await repository.deixarDeSeguir(itemId);
      }
    } on PerfilException catch (e) {
      _itens[index] = anterior;
      _ultimoErroAcao = e.message;
    } finally {
      _idsEmProcessamento.remove(itemId);
      notifyListeners();
    }
  }

  Future<ListaPaginada<UsuarioResumido>> _buscar({required int pagina}) {
    switch (tipo) {
      case TipoRelacionamento.seguidores:
        return repository.buscarSeguidores(
          perfilId,
          pagina: pagina,
          porPagina: porPagina,
        );
      case TipoRelacionamento.seguindo:
        return repository.buscarSeguindo(
          perfilId,
          pagina: pagina,
          porPagina: porPagina,
        );
    }
  }
}
