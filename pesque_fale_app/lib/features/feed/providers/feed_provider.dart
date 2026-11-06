import 'package:flutter/foundation.dart';

import '../../../core/realtime/realtime_manager.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pesquisa/data/pontos_repository.dart';
import '../../pesquisa/domain/filtros_locais.dart';
import '../../pesquisa/domain/ponto.dart';
import '../data/curtidas_repository.dart';
import '../data/eventos_repository.dart';
import '../data/publicacoes_repository.dart';
import '../domain/aba_feed.dart';
import '../domain/evento.dart';
import '../domain/publicacao.dart';
import 'publicacoes_store.dart';

enum StatusAba { inicial, carregando, sucesso, vazio, erro, carregandoMais }

class EstadoAba {
  const EstadoAba({
    required this.status,
    this.mensagemErro,
    this.falhouCarregarMais = false,
  });

  final StatusAba status;
  final String? mensagemErro;
  final bool falhouCarregarMais;

  factory EstadoAba.inicial() => const EstadoAba(status: StatusAba.inicial);
}

class FeedProvider extends ChangeNotifier {
  FeedProvider({
    required this.publicacoesRepo,
    required this.curtidasRepo,
    required this.eventosRepo,
    required this.pontosRepo,
    required this.authProvider,
    required this.realtime,
    required this.store,
  }) : _usuarioId = authProvider.usuario?.id {
    store.addListener(_onStoreMudou);
    realtime.subscribe('nova_publicacao_feed', _onNovaPublicacaoFeed);
    realtime.subscribe('publicacao_criada', _onPublicacaoCriada);
    realtime.subscribe('publicacao_removida', _onPublicacaoRemovida);
    realtime.subscribe('publicacao_curtidas', _onPublicacaoCurtidas);
    realtime.subscribe('publicacao_comentarios', _onPublicacaoComentarios);
    realtime.onReconnect(_onReconnect);
  }

  final PublicacoesRepository publicacoesRepo;
  final CurtidasRepository curtidasRepo;
  final EventosRepository eventosRepo;
  final PontosRepository pontosRepo;
  final RealtimeManager realtime;
  final PublicacoesStore store;
  AuthProvider authProvider;
  String? _usuarioId;
  int _sessao = 0;
  final Map<AbaFeed, Future<void>> _cargasEmVoo = {};

  /// Ids de publicações que chegaram via realtime mas ainda não foram
  /// renderizadas na lista da aba. O provider guarda só o contador bruto:
  /// é a `FeedPage`, que conhece o scroll, quem decide entre mostrar o chip
  /// "X novas publicações" ou aplicar direto ([aplicarPendentes]).
  final Map<AbaFeed, Set<String>> _pendentes = {
    AbaFeed.paraVoce: {},
    AbaFeed.seguindo: {},
  };

  int pendentesCount(AbaFeed aba) => _pendentes[aba]?.length ?? 0;
  int get pendentesParaVoceCount => pendentesCount(AbaFeed.paraVoce);
  int get pendentesSeguindoCount => pendentesCount(AbaFeed.seguindo);

  AbaFeed _abaAtiva = AbaFeed.paraVoce;
  AbaFeed get abaAtiva => _abaAtiva;

  final Map<AbaFeed, EstadoAba> _estados = {
    for (final aba in AbaFeed.values) aba: EstadoAba.inicial(),
  };
  EstadoAba estadoDe(AbaFeed aba) => _estados[aba]!;

  final List<String> _idsParaVoce = [];
  final List<String> _idsSeguindo = [];
  List<Publicacao>? _cacheParaVoce;
  List<Publicacao>? _cacheSeguindo;

  List<Publicacao> get paraVoce =>
      _cacheParaVoce ??= List.unmodifiable(store.resolver(_idsParaVoce));
  List<Publicacao> get seguindo =>
      _cacheSeguindo ??= List.unmodifiable(store.resolver(_idsSeguindo));
  List<Evento> eventos = [];
  List<Ponto> topLocais = [];

  int _paginaParaVoce = 1;
  int _paginaSeguindo = 1;
  bool _temMaisParaVoce = true;
  bool _temMaisSeguindo = true;

  Future<void> trocarAba(AbaFeed nova) async {
    _abaAtiva = nova;
    notifyListeners();
    if (const {
      StatusAba.inicial,
      StatusAba.carregando,
      StatusAba.erro,
      StatusAba.vazio,
    }.contains(estadoDe(nova).status)) {
      await _carregarInicial(nova);
    }
  }

  Future<void> _carregarInicial(AbaFeed aba) {
    final emVoo = _cargasEmVoo[aba];
    if (emVoo != null) return emVoo;
    late final Future<void> carga;
    carga = _buscarInicial(aba).whenComplete(() {
      if (identical(_cargasEmVoo[aba], carga)) _cargasEmVoo.remove(aba);
    });
    _cargasEmVoo[aba] = carga;
    return carga;
  }

  Future<void> _buscarInicial(AbaFeed aba) async {
    final sessao = _sessao;
    _atualizarEstado(aba, StatusAba.carregando);
    try {
      switch (aba) {
        case AbaFeed.paraVoce:
          _pendentes[AbaFeed.paraVoce]!.clear();
          final result = await publicacoesRepo.listar(
            pagina: 1,
            seguindo: false,
          );
          if (sessao != _sessao) return;
          store.upsertTodos(result.items);
          _idsParaVoce
            ..clear()
            ..addAll(result.items.map((p) => p.id));
          _invalidarCache();
          _pendentes[AbaFeed.paraVoce]!.removeWhere(_idsParaVoce.contains);
          _paginaParaVoce = 1;
          _temMaisParaVoce = result.temMais;
          _atualizarEstado(
            aba,
            result.items.isEmpty ? StatusAba.vazio : StatusAba.sucesso,
          );
          break;
        case AbaFeed.seguindo:
          _pendentes[AbaFeed.seguindo]!.clear();
          if (authProvider.usuario == null) {
            _atualizarEstado(aba, StatusAba.vazio);
            break;
          }
          final result = await publicacoesRepo.listar(
            pagina: 1,
            seguindo: true,
          );
          if (sessao != _sessao) return;
          store.upsertTodos(result.items);
          _idsSeguindo
            ..clear()
            ..addAll(result.items.map((p) => p.id));
          _invalidarCache();
          // Evento que chegou com a requisição em voo pode já ter vindo nela.
          _pendentes[AbaFeed.seguindo]!.removeWhere(_idsSeguindo.contains);
          _paginaSeguindo = 1;
          _temMaisSeguindo = result.temMais;
          _atualizarEstado(
            aba,
            result.items.isEmpty ? StatusAba.vazio : StatusAba.sucesso,
          );
          break;
        case AbaFeed.eventos:
          final novos = await eventosRepo.listar(futuros: true, limite: 10);
          if (sessao != _sessao) return;
          eventos = novos;
          _atualizarEstado(
            aba,
            eventos.isEmpty ? StatusAba.vazio : StatusAba.sucesso,
          );
          break;
        case AbaFeed.locais:
          final result = await pontosRepo.buscar(
            filtros: const FiltrosLocais(),
            ordem: 'nota_desc',
          );
          if (sessao != _sessao) return;
          topLocais = result.take(10).toList();
          _atualizarEstado(
            aba,
            topLocais.isEmpty ? StatusAba.vazio : StatusAba.sucesso,
          );
          break;
        case AbaFeed.dicas:
          _atualizarEstado(aba, StatusAba.sucesso);
          break;
      }
    } catch (e) {
      if (sessao != _sessao) return;
      _atualizarEstado(aba, StatusAba.erro, e.toString());
    }
  }

  Future<void> carregarMais() async {
    final aba = _abaAtiva;
    if (aba != AbaFeed.paraVoce && aba != AbaFeed.seguindo) {
      return;
    }
    final atual = estadoDe(aba);
    if (atual.status == StatusAba.carregandoMais ||
        atual.status == StatusAba.carregando ||
        atual.falhouCarregarMais) {
      return;
    }

    final ehSeguindo = aba == AbaFeed.seguindo;
    final temMais = ehSeguindo ? _temMaisSeguindo : _temMaisParaVoce;
    if (!temMais) return;

    final sessao = _sessao;
    _atualizarEstado(aba, StatusAba.carregandoMais);
    try {
      final proximaPagina =
          (ehSeguindo ? _paginaSeguindo : _paginaParaVoce) + 1;
      final result = await publicacoesRepo.listar(
        pagina: proximaPagina,
        seguindo: ehSeguindo,
      );
      if (sessao != _sessao) return;
      store.upsertTodos(result.items);
      // Paginação por offset: publicações novas no topo empurram itens já
      // carregados pra próxima página.
      final ids = ehSeguindo ? _idsSeguindo : _idsParaVoce;
      final idsAtuais = ids.toSet();
      ids.addAll(
        result.items.map((p) => p.id).where((id) => !idsAtuais.contains(id)),
      );
      if (ehSeguindo) {
        _paginaSeguindo = proximaPagina;
        _temMaisSeguindo = result.temMais;
      } else {
        _paginaParaVoce = proximaPagina;
        _temMaisParaVoce = result.temMais;
      }
      _invalidarCache();
      _atualizarEstado(aba, StatusAba.sucesso);
    } catch (_) {
      if (sessao != _sessao) return;
      _estados[aba] = const EstadoAba(
        status: StatusAba.sucesso,
        falhouCarregarMais: true,
      );
      notifyListeners();
    }
  }

  Future<void> tentarCarregarMaisDeNovo() {
    _atualizarEstado(_abaAtiva, StatusAba.sucesso);
    return carregarMais();
  }

  Future<void> pullRefresh() async {
    _pendentes[_abaAtiva]?.clear();
    _estados[_abaAtiva] = EstadoAba.inicial();
    await _carregarInicial(_abaAtiva);
  }

  Future<void> curtirOuDescurtir(Publicacao p) async {
    if (authProvider.usuario == null) {
      throw StateError('não logado');
    }
    final atual = store.porId(p.id);
    if (atual == null) store.upsert(p);
    final base = atual ?? p;
    store.atualizarCurtida(
      base.id,
      jaCurtiu: !base.jaCurtiu,
      curtidasCount: base.jaCurtiu
          ? base.curtidasCount - 1
          : base.curtidasCount + 1,
    );
    try {
      if (base.jaCurtiu) {
        await curtidasRepo.descurtir(base.id);
      } else {
        await curtidasRepo.curtir(base.id);
      }
    } catch (e) {
      store.atualizarCurtida(
        base.id,
        jaCurtiu: base.jaCurtiu,
        curtidasCount: base.curtidasCount,
      );
      rethrow;
    }
  }

  /// Chamado pelo [ComentariosProvider] após criar/deletar um comentário.
  void atualizarContadorComentarios(String publicacaoId, int delta) {
    final atual = store.porId(publicacaoId);
    if (atual == null) return;
    store.atualizarComentarios(publicacaoId, atual.comentariosCount + delta);
  }

  void removerPublicacao(String id) {
    store.remover(id);
  }

  /// Insere uma publicação recém-criada no topo da aba "Para você" e,
  /// se o autor for o usuário logado, também na "Seguindo".
  /// Chamado pela tela de nova publicação após POST bem-sucedido.
  void adicionarPublicacao(Publicacao publicacao) {
    store.upsert(publicacao);
    _idsParaVoce.insert(0, publicacao.id);
    if (_idsSeguindo.isNotEmpty &&
        publicacao.autorId == authProvider.usuario?.id) {
      _idsSeguindo.insert(0, publicacao.id);
    }
    _invalidarCache();
    notifyListeners();
  }

  void _onPublicacaoRemovida(dynamic payload) {
    if (payload is! Map) return;
    final id = payload['publicacaoId'];
    if (id is! String || payload['autorId'] is! String) return;
    store.remover(id);
  }

  void _onPublicacaoCurtidas(dynamic payload) {
    final evento = _contadorDeOutro(payload, 'curtidasCount');
    if (evento == null) return;
    store.atualizarCurtidasCount(evento.publicacaoId, evento.total);
  }

  void _onPublicacaoComentarios(dynamic payload) {
    final evento = _contadorDeOutro(payload, 'comentariosCount');
    if (evento == null) return;
    store.atualizarComentarios(evento.publicacaoId, evento.total);
  }

  ({String publicacaoId, int total})? _contadorDeOutro(
    dynamic payload,
    String campoTotal,
  ) {
    if (payload is! Map) return null;
    final id = payload['publicacaoId'];
    final total = payload[campoTotal];
    final porId = payload['porId'];
    if (id is! String || total is! int || total < 0 || porId is! String) {
      return null;
    }
    if (porId == authProvider.usuario?.id) return null;
    if (store.porId(id) == null) return null;
    return (publicacaoId: id, total: total);
  }

  void _onNovaPublicacaoFeed(dynamic payload) {
    if (payload is! Map) return;
    final id = payload['publicacaoId'];
    final autor = payload['autorId'];
    if (id is! String || autor is! String) return;

    // O autor não ganha chip no próprio feed: a tela de nova publicação já
    // chamou adicionarPublicacao. O backend nem emite pra ele (ninguém segue
    // a si mesmo) — isto é defesa em profundidade.
    _adicionarPendente(AbaFeed.seguindo, id, autor);
  }

  void _onPublicacaoCriada(dynamic payload) {
    if (payload is! Map) return;
    final id = payload['publicacaoId'];
    final autor = payload['autorId'];
    if (id is! String || autor is! String) return;
    _adicionarPendente(AbaFeed.paraVoce, id, autor);
  }

  void _adicionarPendente(AbaFeed aba, String id, String autor) {
    if (autor == authProvider.usuario?.id) return;
    if (_idsDa(aba).contains(id)) return;
    if (!_pendentes[aba]!.add(id)) return;
    notifyListeners();
  }

  List<String> _idsDa(AbaFeed aba) =>
      aba == AbaFeed.seguindo ? _idsSeguindo : _idsParaVoce;

  Future<void> aplicarPendentesSeguindo() => aplicarPendentes(AbaFeed.seguindo);

  Future<void> aplicarPendentesParaVoce() => aplicarPendentes(AbaFeed.paraVoce);

  /// Drena os pendentes buscando a página 1 da aba e colocando no topo
  /// as publicações que ainda não estão na lista. Chamado pela UI no clique
  /// do chip, ou direto quando o usuário já está no topo.
  Future<void> aplicarPendentes(AbaFeed aba) async {
    final pendentes = _pendentes[aba];
    if (pendentes == null || pendentes.isEmpty) return;
    pendentes.clear();
    await _mesclarPaginaUm(aba);
  }

  Future<void> _mesclarPaginaUm(AbaFeed aba) async {
    final sessao = _sessao;
    try {
      final result = await publicacoesRepo.listar(
        pagina: 1,
        seguindo: aba == AbaFeed.seguindo,
      );
      // Logout/troca de conta com a requisição em voo: descarta.
      if (sessao != _sessao) return;
      store.upsertTodos(result.items);
      final ids = _idsDa(aba);
      final idsAtuais = ids.toSet();
      ids.insertAll(
        0,
        result.items.map((p) => p.id).where((id) => !idsAtuais.contains(id)),
      );
      _invalidarCache();
      // A paginação continua de onde estava; o carregarMais dedupa o que
      // o prepend empurrou pra próxima página.
      if (estadoDe(aba).status == StatusAba.vazio && ids.isNotEmpty) {
        _atualizarEstado(aba, StatusAba.sucesso);
      } else {
        notifyListeners();
      }
    } catch (_) {
      // Silencia: o pull-to-refresh continua disponível pra reconciliar.
      notifyListeners();
    }
  }

  void _onReconnect() {
    // Eventos podem ter se perdido na queda: o contador de pendentes deixa de
    // ser confiável e a aba ativa é reconciliada com a página 1.
    if (_pendentes.values.any((p) => p.isNotEmpty)) {
      for (final p in _pendentes.values) {
        p.clear();
      }
      notifyListeners();
    }
    final aba = _abaAtiva;
    if (aba != AbaFeed.paraVoce && aba != AbaFeed.seguindo) return;
    if (aba == AbaFeed.seguindo && authProvider.usuario == null) return;
    if (!const {
      StatusAba.sucesso,
      StatusAba.carregandoMais,
      StatusAba.vazio,
    }.contains(estadoDe(aba).status)) {
      return;
    }
    _mesclarPaginaUm(aba);
  }

  void _onStoreMudou() {
    _idsParaVoce.removeWhere(store.foiRemovida);
    _idsSeguindo.removeWhere(store.foiRemovida);
    _invalidarCache();
    notifyListeners();
  }

  void _invalidarCache() {
    _cacheParaVoce = null;
    _cacheSeguindo = null;
  }

  void _atualizarEstado(AbaFeed aba, StatusAba status, [String? erro]) {
    _estados[aba] = EstadoAba(status: status, mensagemErro: erro);
    notifyListeners();
  }

  void reagirAuth(AuthProvider auth) {
    authProvider = auth;
    final id = auth.usuario?.id;
    if (id == _usuarioId) return;
    _usuarioId = id;
    _reiniciarSessao();
    _carregarInicial(_abaAtiva);
  }

  void _reiniciarSessao() {
    _sessao++;
    _cargasEmVoo.clear();
    _idsParaVoce.clear();
    _idsSeguindo.clear();
    _invalidarCache();
    for (final p in _pendentes.values) {
      p.clear();
    }
    _paginaParaVoce = 1;
    _paginaSeguindo = 1;
    _temMaisParaVoce = true;
    _temMaisSeguindo = true;
    eventos = [];
    topLocais = [];
    for (final aba in AbaFeed.values) {
      _estados[aba] = EstadoAba.inicial();
    }
    store.limpar();
    notifyListeners();
  }

  @override
  void dispose() {
    store.removeListener(_onStoreMudou);
    realtime.unsubscribe('nova_publicacao_feed', _onNovaPublicacaoFeed);
    realtime.unsubscribe('publicacao_criada', _onPublicacaoCriada);
    realtime.unsubscribe('publicacao_removida', _onPublicacaoRemovida);
    realtime.unsubscribe('publicacao_curtidas', _onPublicacaoCurtidas);
    realtime.unsubscribe('publicacao_comentarios', _onPublicacaoComentarios);
    realtime.removerOnReconnect(_onReconnect);
    super.dispose();
  }
}
