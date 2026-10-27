import 'package:flutter/foundation.dart';

import '../../../core/realtime/realtime_manager.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/conversas_repository.dart';
import '../domain/conversa.dart';

enum StatusInbox { carregando, carregado, erro }

/// Lista de conversas do usuário logado. Vive o app inteiro (global no
/// `main.dart`) pra receber os eventos realtime mesmo com a aba Chat fora
/// da tela — o badge do bottom nav deriva desta lista.
///
/// Carrega sozinho quando o auth passa a ter sessão ([reagirAuth]) e se
/// mantém em dia via `nova_conversa` / `nova_mensagem_em_conversa` /
/// `conversa_lida`.
class InboxProvider extends ChangeNotifier {
  InboxProvider({required this.repository, required this.realtime}) {
    realtime.subscribe('nova_conversa', _onNovaConversa);
    realtime.subscribe('nova_mensagem_em_conversa', _onNovaMensagemEmConversa);
    realtime.subscribe('conversa_lida', _onConversaLida);
    realtime.onReconnect(_onReconnect);
  }

  final ConversasRepository repository;
  final RealtimeManager realtime;

  StatusInbox status = StatusInbox.carregando;
  List<Conversa> _todas = [];
  String _termoBusca = '';

  /// Id do usuário logado. É estado do provider, não do closure dos
  /// callbacks — assim cumpre o contrato stateless do [RealtimeManager]:
  /// os handlers leem o valor atual da instância, que troca junto com a conta.
  String? _meuId;

  /// Incrementada no [resetar]; descarta respostas de [carregar]/[refresh]
  /// que ainda estavam em voo quando a sessão mudou.
  int _geracao = 0;

  /// Retorna as conversas filtradas:
  /// - Sempre remove chats vazios (ultimaMensagem == null)
  /// - Aplica termo de busca por outroNome/outroUsername
  List<Conversa> get conversas {
    final comMensagem = _todas.where((c) => c.temMensagem);
    if (_termoBusca.trim().isEmpty) return comMensagem.toList();
    final termo = _termoBusca.toLowerCase().trim();
    return comMensagem
        .where(
          (c) =>
              c.outroNome.toLowerCase().contains(termo) ||
              c.outroUsername.toLowerCase().contains(termo),
        )
        .toList();
  }

  /// Todas as conversas, sem filtro de busca — pra quem precisa contar
  /// sobre a lista inteira (ex.: badge do bottom nav).
  List<Conversa> get conversasInternas => List.unmodifiable(_todas);

  String get termoBusca => _termoBusca;
  bool get temAlgumaConversa => _todas.any((c) => c.temMensagem);

  Future<void> carregar() async {
    final geracao = _geracao;
    status = StatusInbox.carregando;
    notifyListeners();
    try {
      final todas = await repository.listar();
      if (geracao != _geracao) return;
      _todas = todas;
      status = StatusInbox.carregado;
    } catch (_) {
      if (geracao != _geracao) return;
      status = StatusInbox.erro;
    }
    notifyListeners();
  }

  void setTermoBusca(String termo) {
    _termoBusca = termo;
    notifyListeners();
  }

  Future<void> refresh() async {
    final geracao = _geracao;
    try {
      final todas = await repository.listar();
      if (geracao != _geracao) return;
      _todas = todas;
      status = StatusInbox.carregado;
    } catch (_) {
      // Silencia erro no refresh — mantém os dados já carregados na tela.
    }
    if (geracao != _geracao) return;
    notifyListeners();
  }

  /// Chamado pelo `ChangeNotifierProxyProvider` a cada mudança no auth.
  /// Só age quando a conta muda (login, logout ou troca direta de conta) —
  /// outras notificações do auth (ex.: editar perfil) não recarregam.
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
    _termoBusca = '';
    status = StatusInbox.carregando;
    notifyListeners();
  }

  void _onNovaConversa(dynamic payload) {
    if (payload is! Map) return;
    final conversaId = payload['conversaId'] as String?;
    final remetente = payload['remetente'];
    final ultima = payload['ultimaMensagem'];
    if (conversaId == null || remetente is! Map || ultima is! Map) return;
    if (_todas.any((c) => c.id == conversaId)) return;

    if (remetente['id'] == _meuId) {
      // O payload só traz os dados do remetente; pra quem enviou, o "outro"
      // da conversa é o destinatário — busca a lista do backend.
      refresh();
      return;
    }

    final enviadaEm = _parseData(ultima['criadoEm']) ?? DateTime.now();
    final conversa = Conversa(
      id: conversaId,
      outroId: remetente['id'] as String,
      outroNome: remetente['nome'] as String? ?? '',
      outroUsername: remetente['username'] as String? ?? '',
      outroFoto: remetente['fotoUrl'] as String?,
      ultimaMensagem: ultima['texto'] as String?,
      ultimaMensagemEm: enviadaEm,
      naoLidas: 1,
      criadoEm: enviadaEm,
    );
    _todas = [conversa, ..._todas];
    notifyListeners();
  }

  void _onNovaMensagemEmConversa(dynamic payload) {
    if (payload is! Map) return;
    final i = _todas.indexWhere((c) => c.id == payload['conversaId']);
    // Conversa ainda fora da lista (ex.: evento chegou antes do load): ignora.
    if (i == -1) return;

    final atual = _todas[i];
    final enviadaEm = _parseData(payload['timestamp']);
    if (enviadaEm == null) return;
    // A primeira mensagem chega duas vezes (nova_conversa e logo depois este
    // evento), e um refresh pode já ter trazido a mensagem: não conta de novo.
    final ultimaConhecida = atual.ultimaMensagemEm;
    if (ultimaConhecida != null && !enviadaEm.isAfter(ultimaConhecida)) return;

    final souRemetente = payload['remetenteId'] == _meuId;
    final atualizada = atual.copyWith(
      ultimaMensagem: payload['previewTexto'] as String?,
      ultimaMensagemEm: enviadaEm,
      naoLidas: souRemetente ? atual.naoLidas : atual.naoLidas + 1,
    );
    _todas = [atualizada, ..._todas.where((c) => c.id != atual.id)];
    notifyListeners();
  }

  void _onConversaLida(dynamic payload) {
    if (payload is! Map) return;
    // O evento vai pros dois participantes; só a leitura feita por mim (em
    // qualquer dispositivo) mexe no meu contador.
    if (payload['lidaPor'] != _meuId) return;
    final i = _todas.indexWhere((c) => c.id == payload['conversaId']);
    if (i == -1) return;
    final atual = _todas[i];
    if (atual.naoLidas == 0) return;
    // Lista nova em vez de mutar no lugar, como nos outros handlers.
    _todas = List.of(_todas)..[i] = atual.copyWith(naoLidas: 0);
    notifyListeners();
  }

  void _onReconnect() {
    if (_meuId != null) refresh();
  }

  static DateTime? _parseData(dynamic valor) =>
      valor is String ? DateTime.tryParse(valor)?.toLocal() : null;

  @override
  void dispose() {
    realtime.unsubscribe('nova_conversa', _onNovaConversa);
    realtime.unsubscribe(
      'nova_mensagem_em_conversa',
      _onNovaMensagemEmConversa,
    );
    realtime.unsubscribe('conversa_lida', _onConversaLida);
    realtime.removerOnReconnect(_onReconnect);
    super.dispose();
  }
}
