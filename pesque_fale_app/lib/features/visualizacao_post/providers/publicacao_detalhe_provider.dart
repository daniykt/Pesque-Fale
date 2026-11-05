import 'package:flutter/foundation.dart';

import '../../feed/data/publicacoes_repository.dart';
import '../../feed/domain/publicacao.dart';
import '../../feed/providers/publicacoes_store.dart';

enum StatusDetalhe { carregando, carregado, erro, removida }

class PublicacaoDetalheProvider extends ChangeNotifier {
  PublicacaoDetalheProvider({
    required this.publicacoesRepository,
    required this.store,
    Publicacao? publicacaoInicial,
    String? publicacaoId,
  }) : assert(
         publicacaoInicial != null || publicacaoId != null,
         'Precisa de publicacao hidratada OU id',
       ),
       _publicacaoId = publicacaoId ?? publicacaoInicial!.id,
       _ultima = publicacaoInicial {
    store.addListener(_onStoreMudou);
  }

  final PublicacoesRepository publicacoesRepository;
  final PublicacoesStore store;
  final String _publicacaoId;
  Publicacao? _ultima;

  Publicacao? get publicacao => store.porId(_publicacaoId) ?? _ultima;

  StatusDetalhe status = StatusDetalhe.carregando;
  String? mensagemErro;
  bool _excluindo = false;
  bool get excluindo => _excluindo;
  bool _excluidaAqui = false;
  bool get excluidaAqui => _excluidaAqui;

  Future<void> carregar() async {
    if (store.foiRemovida(_publicacaoId)) {
      status = StatusDetalhe.removida;
      notifyListeners();
      return;
    }
    if (publicacao != null) {
      status = StatusDetalhe.carregado;
      notifyListeners();
      return;
    }

    status = StatusDetalhe.carregando;
    mensagemErro = null;
    notifyListeners();
    try {
      final carregada = await publicacoesRepository.buscarPorId(_publicacaoId);
      _ultima = carregada;
      store.upsert(carregada);
      status = StatusDetalhe.carregado;
    } catch (e) {
      status = StatusDetalhe.erro;
      mensagemErro = e.toString();
    }
    notifyListeners();
  }

  Future<void> excluir() async {
    if (publicacao == null || _excluindo) return;
    _excluindo = true;
    notifyListeners();
    try {
      await publicacoesRepository.deletar(_publicacaoId);
      _excluidaAqui = true;
      store.remover(_publicacaoId);
    } finally {
      _excluindo = false;
      notifyListeners();
    }
  }

  void aplicarDeltaComentarios(int delta) {
    final atual = publicacao;
    if (atual == null) return;
    store.upsert(
      atual.copyWith(comentariosCount: atual.comentariosCount + delta),
    );
  }

  void _onStoreMudou() {
    if (store.foiRemovida(_publicacaoId)) {
      if (status == StatusDetalhe.removida) return;
      status = StatusDetalhe.removida;
      notifyListeners();
      return;
    }
    final atual = store.porId(_publicacaoId);
    if (atual == null || identical(atual, _ultima)) return;
    _ultima = atual;
    notifyListeners();
  }

  @override
  void dispose() {
    store.removeListener(_onStoreMudou);
    super.dispose();
  }
}
