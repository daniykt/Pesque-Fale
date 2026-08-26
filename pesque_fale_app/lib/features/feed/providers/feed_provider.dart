import 'package:flutter/foundation.dart';

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
  });

  final PublicacoesRepository publicacoesRepo;
  final CurtidasRepository curtidasRepo;
  final EventosRepository eventosRepo;
  final PontosRepository pontosRepo;
  AuthProvider authProvider;

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
        seguindo.addAll(result.items);
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
      _estados[AbaFeed.seguindo] = EstadoAba.inicial();
      notifyListeners();
    }
  }
}
