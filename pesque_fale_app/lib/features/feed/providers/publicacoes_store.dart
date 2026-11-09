import 'package:flutter/foundation.dart';

import '../domain/publicacao.dart';

class PublicacoesStore extends ChangeNotifier {
  final Map<String, Publicacao> _porId = {};
  final Set<String> _removidos = {};

  Publicacao? porId(String id) => _porId[id];

  bool foiRemovida(String id) => _removidos.contains(id);

  List<Publicacao> resolver(List<String> ids) => [
    for (final id in ids)
      if (_porId[id] != null) _porId[id]!,
  ];

  Iterable<Publicacao> publicacoesDoAutor(String autorId) =>
      _porId.values.where((p) => p.autorId == autorId);

  void upsert(Publicacao p) {
    if (_aplicar(p)) notifyListeners();
  }

  void upsertTodos(Iterable<Publicacao> lista) {
    var mudou = false;
    for (final p in lista) {
      if (_aplicar(p)) mudou = true;
    }
    if (mudou) notifyListeners();
  }

  void inserirSeAusente(Iterable<Publicacao> lista) {
    var mudou = false;
    for (final p in lista) {
      if (_removidos.contains(p.id) || _porId.containsKey(p.id)) continue;
      _porId[p.id] = p;
      mudou = true;
    }
    if (mudou) notifyListeners();
  }

  void remover(String id) {
    final existia = _porId.remove(id) != null;
    final novo = _removidos.add(id);
    if (existia || novo) notifyListeners();
  }

  void atualizarCurtida(
    String id, {
    required bool jaCurtiu,
    required int curtidasCount,
  }) {
    final atual = _porId[id];
    if (atual == null) return;
    if (atual.jaCurtiu == jaCurtiu && atual.curtidasCount == curtidasCount) {
      return;
    }
    _porId[id] = atual.copyWith(
      jaCurtiu: jaCurtiu,
      curtidasCount: curtidasCount,
    );
    notifyListeners();
  }

  void atualizarCurtidasCount(String id, int total) {
    final atual = _porId[id];
    if (atual == null || atual.curtidasCount == total) return;
    _porId[id] = atual.copyWith(curtidasCount: total);
    notifyListeners();
  }

  void atualizarComentarios(String id, int total) {
    final atual = _porId[id];
    if (atual == null || atual.comentariosCount == total) return;
    _porId[id] = atual.copyWith(comentariosCount: total);
    notifyListeners();
  }

  void limpar() {
    if (_porId.isEmpty && _removidos.isEmpty) return;
    _porId.clear();
    _removidos.clear();
    notifyListeners();
  }

  bool _aplicar(Publicacao p) {
    if (_removidos.contains(p.id)) return false;
    final atual = _porId[p.id];
    if (atual != null && _igual(atual, p)) return false;
    _porId[p.id] = p;
    return true;
  }

  bool _igual(Publicacao a, Publicacao b) =>
      a.descricao == b.descricao &&
      a.imagemUrl == b.imagemUrl &&
      a.localTexto == b.localTexto &&
      a.avaliacaoNota == b.avaliacaoNota &&
      listEquals(a.tags, b.tags) &&
      a.curtidasCount == b.curtidasCount &&
      a.comentariosCount == b.comentariosCount &&
      a.jaCurtiu == b.jaCurtiu &&
      a.autorNome == b.autorNome &&
      a.autorFoto == b.autorFoto &&
      a.atualizadoEm == b.atualizadoEm;
}
