import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/realtime/realtime_manager.dart';
import '../../auth/providers/auth_provider.dart';
import '../../perfil/data/perfil_repository.dart';
import '../data/notificacoes_repository.dart';
import '../domain/notificacao.dart';

enum StatusNotificacoes { carregando, carregado, erro }

/// Lista de notificações do usuário logado. Vive o app inteiro (global no
/// `main.dart`) pra receber `nova_notificacao` mesmo com a aba Alertas fora
/// da tela — o badge do bottom nav deriva desta lista.
///
/// Carrega sozinho quando o auth passa a ter sessão ([reagirAuth]). Marcar
/// como lidas no servidor só acontece quando a aba Alertas abre
/// (`carregar(marcarComoLidas: true)`).
class NotificacoesProvider extends ChangeNotifier {
  NotificacoesProvider({
    required this.repository,
    required this.perfilRepository,
    required this.realtime,
  }) {
    realtime.subscribe('nova_notificacao', _onNovaNotificacao);
    realtime.onReconnect(_onReconnect);
  }

  final NotificacoesRepository repository;
  final PerfilRepository perfilRepository;
  final RealtimeManager realtime;

  StatusNotificacoes status = StatusNotificacoes.carregando;
  List<Notificacao> _todas = [];
  TipoNotificacao? _filtro;
  final Map<String, ({Notificacao notificacao, int indice})> _remocoesPendentes = {};
  bool _descartado = false;

  /// Ids que o usuário já viu na aba Alertas. Elas continuam com
  /// `lida: false` na lista local (pro indicador visual da sessão), mas não
  /// contam mais pro badge.
  final Set<String> _vistas = {};

  /// Id do usuário logado. É estado do provider, não do closure dos
  /// callbacks — cumpre o contrato stateless do [RealtimeManager].
  String? _meuId;

  /// Incrementada no [resetar]; descarta respostas que ainda estavam em voo
  /// quando a sessão mudou.
  int _geracao = 0;

  List<Notificacao> get notificacoes {
    if (_filtro == null) return _todas;
    return _todas.where((n) => n.tipo == _filtro).toList();
  }

  /// Notificações não lidas que o usuário ainda não viu — o que o badge do
  /// bottom nav mostra.
  int get naoVistas =>
      _todas.where((n) => !n.lida && !_vistas.contains(n.id)).length;

  TipoNotificacao? get filtro => _filtro;
  bool get temAlguma => _todas.isNotEmpty;

  /// Busca a lista no servidor. Com [marcarComoLidas] (aba Alertas abrindo),
  /// também marca todas como lidas no backend — sem mexer no `lida` local,
  /// que segura o indicador visual até o próximo carregamento.
  Future<void> carregar({bool marcarComoLidas = false}) async {
    final geracao = _geracao;
    if (marcarComoLidas) _marcarVistas();
    status = StatusNotificacoes.carregando;
    notifyListeners();
    try {
      final resultado = await repository.listar();
      if (geracao != _geracao) return;
      // TODO(8.4.4): remover este filtro quando o backend parar de criar
      // notificações do tipo `mensagem` em chat.gateway.js. Mensagens têm sua
      // própria aba (Chat) com badge próprio no bottom nav — não devem
      // aparecer na lista de alertas sociais.
      _todas = _semPendentes(_semMensagens(resultado.lista));
      status = StatusNotificacoes.carregado;
      if (marcarComoLidas && _marcarVistas()) {
        await repository.marcarTodasComoLidas();
      }
    } catch (_) {
      if (geracao != _geracao) return;
      status = StatusNotificacoes.erro;
    }
    if (geracao != _geracao) return;
    notifyListeners();
  }

  Future<void> refresh() async {
    final geracao = _geracao;
    try {
      final resultado = await repository.listar();
      if (geracao != _geracao) return;
      _todas = _semPendentes(_semMensagens(resultado.lista));
      status = StatusNotificacoes.carregado;
      notifyListeners();
    } catch (_) {
      // Silencia erro no refresh — mantém os dados já carregados na tela.
    }
  }

  /// Chamado pelo `ChangeNotifierProxyProvider` a cada mudança no auth.
  /// Só age quando a conta muda (login, logout ou troca direta de conta).
  void reagirAuth(AuthProvider auth) {
    final id = auth.estaLogado ? auth.usuario?.id : null;
    if (id == _meuId) return;
    if (_meuId != null) resetar();
    _meuId = id;
    if (id != null) carregar();
  }

  void resetar() {
    _geracao++;
    _meuId = null;
    _todas = [];
    _filtro = null;
    _remocoesPendentes.clear();
    _vistas.clear();
    status = StatusNotificacoes.carregando;
    notifyListeners();
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

  /// Marca TODAS as notificações atuais como vistas localmente (não como
  /// lidas no servidor — isso é do [carregar] com `marcarComoLidas: true`).
  /// A `NotificacoesPage` chama enquanto está ativa, pra o badge não subir
  /// com o usuário já olhando a lista. Só notifica se algo mudou.
  void marcarTodasComoVistas() {
    final antes = _vistas.length;
    _vistas.addAll(_todas.map((n) => n.id));
    if (_vistas.length == antes) return;
    notifyListeners();
  }

  /// Marca como vistas as não lidas da lista atual. Retorna se havia alguma.
  bool _marcarVistas() {
    final naoLidas = _todas.where((n) => !n.lida).map((n) => n.id);
    _vistas.addAll(naoLidas);
    return naoLidas.isNotEmpty;
  }

  void _onNovaNotificacao(dynamic payload) {
    if (payload is! Map) return;
    final Notificacao n;
    try {
      n = Notificacao.fromJson(Map<String, dynamic>.from(payload));
    } catch (_) {
      return;
    }
    // Mesmo filtro do carregar (TODO 8.4.4).
    if (n.tipo == TipoNotificacao.mensagem) return;
    if (_todas.any((x) => x.id == n.id)) return;
    // Chega com `lida: false` e fica assim: quem marca como lida é a aba
    // Alertas ao abrir, não o evento.
    _todas = [n, ..._todas];
    notifyListeners();
  }

  void _onReconnect() {
    if (_meuId != null) refresh();
  }

  List<Notificacao> _semPendentes(List<Notificacao> lista) =>
      lista.where((n) => !_remocoesPendentes.containsKey(n.id)).toList();

  List<Notificacao> _semMensagens(List<Notificacao> lista) =>
      lista.where((n) => n.tipo != TipoNotificacao.mensagem).toList();

  @override
  void notifyListeners() {
    if (!_descartado) super.notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    realtime.unsubscribe('nova_notificacao', _onNovaNotificacao);
    realtime.removerOnReconnect(_onReconnect);
    super.dispose();
  }
}
