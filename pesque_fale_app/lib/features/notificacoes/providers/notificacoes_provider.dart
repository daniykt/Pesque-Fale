import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../perfil/data/perfil_repository.dart';
import '../data/notificacoes_repository.dart';
import '../domain/notificacao.dart';

enum StatusNotificacoes { carregando, carregado, erro }

class NotificacoesProvider extends ChangeNotifier {
  NotificacoesProvider({required this.repository, required this.perfilRepository});

  final NotificacoesRepository repository;
  final PerfilRepository perfilRepository;

  StatusNotificacoes status = StatusNotificacoes.carregando;
  List<Notificacao> _todas = [];
  TipoNotificacao? _filtro;
  final Map<String, ({Notificacao notificacao, int indice})> _remocoesPendentes = {};
  bool _descartado = false;

  List<Notificacao> get notificacoes {
    if (_filtro == null) return _todas;
    return _todas.where((n) => n.tipo == _filtro).toList();
  }

  TipoNotificacao? get filtro => _filtro;
  bool get temAlguma => _todas.isNotEmpty;

  Future<void> carregar() async {
    status = StatusNotificacoes.carregando;
    notifyListeners();
    try {
      final resultado = await repository.listar();
      _todas = _semPendentes(resultado.lista);
      status = StatusNotificacoes.carregado;
      if (_todas.any((n) => !n.lida)) {
        await repository.marcarTodasComoLidas();
        // NÃO atualiza estado local — mantém 'lida: false' para highlight visual.
      }
    } catch (_) {
      status = StatusNotificacoes.erro;
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      final resultado = await repository.listar();
      _todas = _semPendentes(resultado.lista);
      notifyListeners();
    } catch (_) {
      // Silencia erro no refresh — mantém os dados já carregados na tela.
    }
  }

  void setFiltro(TipoNotificacao? tipo) {
    _filtro = tipo;
    notifyListeners();
  }

  void marcarLidaLocal(String id) {
    final idx = _todas.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _todas[idx] = _todas[idx].copyWith(lida: true);
    notifyListeners();
  }

  Future<bool> seguirDeVolta(Notificacao n) async {
    if (n.deId == null) return false;
    try {
      await perfilRepository.seguir(n.deId!);
      final idx = _todas.indexWhere((x) => x.id == n.id);
      if (idx != -1) {
        _todas[idx] = _todas[idx].copyWith(jaSigoDe: true);
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  bool removerLocal(String id) {
    final indice = _todas.indexWhere((n) => n.id == id);
    if (indice == -1) return false;
    final removida = _todas.removeAt(indice);
    _remocoesPendentes[id] = (notificacao: removida, indice: indice);
    notifyListeners();
    return true;
  }

  void desfazerRemocao(String id) {
    final pendente = _remocoesPendentes.remove(id);
    if (pendente == null) return;
    _todas.insert(math.min(pendente.indice, _todas.length), pendente.notificacao);
    notifyListeners();
  }

  Future<bool> confirmarRemocao(String id) async {
    if (!_remocoesPendentes.containsKey(id)) return true;
    try {
      await repository.apagar(id);
      _remocoesPendentes.remove(id);
      return true;
    } catch (_) {
      desfazerRemocao(id);
      return false;
    }
  }

  Future<bool> limparTodas() async {
    try {
      await repository.apagarTodas();
      _todas = [];
      _remocoesPendentes.clear();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  List<Notificacao> _semPendentes(List<Notificacao> lista) =>
      lista.where((n) => !_remocoesPendentes.containsKey(n.id)).toList();

  @override
  void notifyListeners() {
    if (!_descartado) super.notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}