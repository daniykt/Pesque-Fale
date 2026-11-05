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
  const EstadoAba({required this.status, this.mensagemErro});

  final StatusAba status;
  final String? mensagemErro;

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
  /// renderizadas na lista Seguindo. O provider guarda só o contador bruto:
  /// é a `FeedPage`, que conhece o scroll, quem decide entre mostrar o chip
  /// "X novas publicações" ou aplicar direto ([aplicarPendentesSeguindo]).
  final Set<String> _pendentesSeguindo = {};

  int get pendentesSeguindoCount => _pendentesSeguindo.length;

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
          _paginaParaVoce = 1;
          _temMaisParaVoce = result.temMais;
          _atualizarEstado(
            aba,
            result.items.isEmpty ? StatusAba.vazio : StatusAba.sucesso,
          );
          break;
        case AbaFeed.seguindo:
          _pendentesSeguindo.clear();
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
          _pendentesSeguindo.removeWhere(_idsSeguindo.contains);
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
    if (_abaAtiva != AbaFeed.paraVoce && _abaAtiva != AbaFeed.seguindo) {
      return;
    }
    final atual = estadoDe(_abaAtiva);
    if (atual.status == StatusAba.carregandoMais ||
        atual.status == StatusAba.carregando) {
      return;
    }

    final ehSeguindo = _abaAtiva == AbaFeed.seguindo;
    final temMais = ehSeguindo ? _temMaisSeguindo : _temMaisParaVoce;
    if (!temMais) return;

    final sessao = _sessao;
    _atualizarEstado(_abaAtiva, StatusAba.carregandoMais);
    try {
      final proximaPagina =
          (ehSeguindo ? _paginaSeguindo : _paginaParaVoce) + 1;
      final result = await publicacoesRepo.listar(
        pagina: proximaPagina,
        seguindo: ehSeguindo,
      );
      if (sessao != _sessao) return;
      store.upsertTodos(result.items);
      if (ehSeguindo) {
        // Paginação por offset: publicações aplicadas no topo via realtime
        // empurram itens já carregados pra próxima página.
        final idsAtuais = _idsSeguindo.toSet();
        _idsSeguindo.addAll(
          result.items.map((p) => p.id).where((id) => !idsAtuais.contains(id)),
        );
        _paginaSeguindo = proximaPagina;
        _temMaisSeguindo = result.temMais;
      } else {
        _idsParaVoce.addAll(result.items.map((p) => p.id));
        _paginaParaVoce = proximaPagina;
        _temMaisParaVoce = result.temMais;
      }
      _invalidarCache();
      _atualizarEstado(_abaAtiva, StatusAba.sucesso);
    } catch (e) {
      if (sessao != _sessao) return;
      _atualizarEstado(_abaAtiva, StatusAba.erro, e.toString());
    }
  }

  Future<void> pullRefresh() async {
    if (_abaAtiva == AbaFeed.seguindo) _pendentesSeguindo.clear();
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

  void _onNovaPublicacaoFeed(dynamic payload) {
    if (payload is! Map) return;
    final id = payload['publicacaoId'];
    final autor = payload['autorId'];
    if (id is! String || autor is! String) return;

    // O autor não ganha chip no próprio feed: a tela de nova publicação já
    // chamou adicionarPublicacao. O backend nem emite pra ele (ninguém segue
    // a si mesmo) — isto é defesa em profundidade.
    if (autor == authProvider.usuario?.id) return;
    if (_idsSeguindo.contains(id)) return;
    if (!_pendentesSeguindo.add(id)) return;
    notifyListeners();
  }

  /// Drena os pendentes buscando a página 1 do Seguindo e colocando no topo
  /// as publicações que ainda não estão na lista. Chamado pela UI no clique
  /// do chip, ou direto quando o usuário já está no topo.
  Future<void> aplicarPendentesSeguindo() async {
    if (_pendentesSeguindo.isEmpty) return;
    _pendentesSeguindo.clear();
    final usuarioId = authProvider.usuario?.id;
    try {
      final result = await publicacoesRepo.listar(pagina: 1, seguindo: true);
      // Logout/troca de conta com a requisição em voo: descarta.
      if (authProvider.usuario?.id != usuarioId) return;
      store.upsertTodos(result.items);
      final idsAtuais = _idsSeguindo.toSet();
      _idsSeguindo.insertAll(
        0,
        result.items.map((p) => p.id).where((id) => !idsAtuais.contains(id)),
      );
      _invalidarCache();
      // A paginação continua de onde estava; o carregarMais dedupa o que
      // o prepend empurrou pra próxima página.
      _atualizarEstado(
        AbaFeed.seguindo,
        _idsSeguindo.isEmpty ? StatusAba.vazio : StatusAba.sucesso,
      );
    } catch (_) {
      // Silencia: o pull-to-refresh continua disponível pra reconciliar.
      notifyListeners();
    }
  }

  void _onReconnect() {
    // Eventos podem ter se perdido na queda; o contador deixa de ser
    // confiável. O próximo pull-to-refresh (ou troca de aba) reconcilia.
    if (_pendentesSeguindo.isEmpty) return;
    _pendentesSeguindo.clear();
    notifyListeners();
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
    _pendentesSeguindo.clear();
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
    realtime.removerOnReconnect(_onReconnect);
    super.dispose();
  }
}
