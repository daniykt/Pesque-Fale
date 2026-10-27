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
  }) {
    realtime.subscribe('nova_publicacao_feed', _onNovaPublicacaoFeed);
    realtime.onReconnect(_onReconnect);
  }

  final PublicacoesRepository publicacoesRepo;
  final CurtidasRepository curtidasRepo;
  final EventosRepository eventosRepo;
  final PontosRepository pontosRepo;
  final RealtimeManager realtime;
  AuthProvider authProvider;

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

  final List<Publicacao> paraVoce = [];
  final List<Publicacao> seguindo = [];
  List<Evento> eventos = [];
  List<Ponto> topLocais = [];

  int _paginaParaVoce = 1;
  int _paginaSeguindo = 1;
  bool _temMaisParaVoce = true;
  bool _temMaisSeguindo = true;

  Future<void> trocarAba(AbaFeed nova) async {
    _abaAtiva = nova;
    notifyListeners();
    if (estadoDe(nova).status == StatusAba.inicial) {
      await _carregarInicial(nova);
    }
  }

  Future<void> _carregarInicial(AbaFeed aba) async {
    _atualizarEstado(aba, StatusAba.carregando);
    try {
      switch (aba) {
        case AbaFeed.paraVoce:
          final result = await publicacoesRepo.listar(
            pagina: 1,
            seguindo: false,
          );
          paraVoce
            ..clear()
            ..addAll(result.items);
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
          seguindo
            ..clear()
            ..addAll(result.items);
          // Evento que chegou com a requisição em voo pode já ter vindo nela.
          _pendentesSeguindo.removeWhere(
            (id) => seguindo.any((p) => p.id == id),
          );
          _paginaSeguindo = 1;
          _temMaisSeguindo = result.temMais;
          _atualizarEstado(
            aba,
            result.items.isEmpty ? StatusAba.vazio : StatusAba.sucesso,
          );
          break;
        case AbaFeed.eventos:
          eventos = await eventosRepo.listar(futuros: true, limite: 10);
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

    _atualizarEstado(_abaAtiva, StatusAba.carregandoMais);
    try {
      final proximaPagina =
          (ehSeguindo ? _paginaSeguindo : _paginaParaVoce) + 1;
      final result = await publicacoesRepo.listar(
        pagina: proximaPagina,
        seguindo: ehSeguindo,
      );
      if (ehSeguindo) {
        // Paginação por offset: publicações aplicadas no topo via realtime
        // empurram itens já carregados pra próxima página.
        final idsAtuais = seguindo.map((p) => p.id).toSet();
        seguindo.addAll(result.items.where((p) => !idsAtuais.contains(p.id)));
        _paginaSeguindo = proximaPagina;
        _temMaisSeguindo = result.temMais;
      } else {
        paraVoce.addAll(result.items);
        _paginaParaVoce = proximaPagina;
        _temMaisParaVoce = result.temMais;
      }
      _atualizarEstado(_abaAtiva, StatusAba.sucesso);
    } catch (e) {
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
    final atualizado = p.copyWith(
      jaCurtiu: !p.jaCurtiu,
      curtidasCount: p.jaCurtiu ? p.curtidasCount - 1 : p.curtidasCount + 1,
    );
    _substituirEmTodasListas(atualizado);
    notifyListeners();
    try {
      if (p.jaCurtiu) {
        await curtidasRepo.descurtir(p.id);
      } else {
        await curtidasRepo.curtir(p.id);
      }
    } catch (e) {
      _substituirEmTodasListas(p);
      notifyListeners();
      rethrow;
    }
  }

  /// Chamado pelo [ComentariosProvider] após criar/deletar um comentário.
  void atualizarContadorComentarios(String publicacaoId, int delta) {
    Publicacao? achado;
    for (final lista in [paraVoce, seguindo]) {
      final idx = lista.indexWhere((p) => p.id == publicacaoId);
      if (idx != -1) {
        achado = lista[idx].copyWith(
          comentariosCount: lista[idx].comentariosCount + delta,
        );
        lista[idx] = achado;
      }
    }
    if (achado != null) notifyListeners();
  }

  void removerPublicacao(String id) {
    paraVoce.removeWhere((p) => p.id == id);
    seguindo.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// Insere uma publicação recém-criada no topo da aba "Para você" e,
  /// se o autor for o usuário logado, também na "Seguindo".
  /// Chamado pela tela de nova publicação após POST bem-sucedido.
  void adicionarPublicacao(Publicacao publicacao) {
    paraVoce.insert(0, publicacao);
    if (seguindo.isNotEmpty && publicacao.autorId == authProvider.usuario?.id) {
      seguindo.insert(0, publicacao);
    }
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
    if (seguindo.any((p) => p.id == id)) return;
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
      final idsAtuais = seguindo.map((p) => p.id).toSet();
      seguindo.insertAll(
        0,
        result.items.where((p) => !idsAtuais.contains(p.id)),
      );
      // A paginação continua de onde estava; o carregarMais dedupa o que
      // o prepend empurrou pra próxima página.
      _atualizarEstado(
        AbaFeed.seguindo,
        seguindo.isEmpty ? StatusAba.vazio : StatusAba.sucesso,
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

  void _substituirEmTodasListas(Publicacao nova) {
    for (final lista in [paraVoce, seguindo]) {
      final idx = lista.indexWhere((p) => p.id == nova.id);
      if (idx != -1) lista[idx] = nova;
    }
  }

  void _atualizarEstado(AbaFeed aba, StatusAba status, [String? erro]) {
    _estados[aba] = EstadoAba(status: status, mensagemErro: erro);
    notifyListeners();
  }

  /// Reage a login/logout do usuário: ao deslogar, esvazia a aba Seguindo
  /// (que exige autenticação) para forçar um novo carregamento na próxima
  /// vez que for aberta.
  void reagirAuth(AuthProvider auth) {
    authProvider = auth;
    if (auth.usuario == null) {
      seguindo.clear();
      _pendentesSeguindo.clear();
      _estados[AbaFeed.seguindo] = EstadoAba.inicial();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    realtime.unsubscribe('nova_publicacao_feed', _onNovaPublicacaoFeed);
    realtime.removerOnReconnect(_onReconnect);
    super.dispose();
  }
}
