import 'package:flutter/foundation.dart';

import '../../auth/providers/auth_provider.dart';
import '../../pesquisa/data/pontos_exceptions.dart';
import '../../pesquisa/data/pontos_repository.dart';
import '../../pesquisa/domain/ponto.dart';
import '../data/avaliacoes_exceptions.dart';
import '../data/avaliacoes_repository.dart';
import '../domain/avaliacao.dart';

enum PontoDetalheStatus { carregando, sucesso, erro }

class PontoDetalheProvider extends ChangeNotifier {
  PontoDetalheProvider({
    required this.pontosRepository,
    required this.avaliacoesRepository,
    required this.authProvider,
  });

  final PontosRepository pontosRepository;
  final AvaliacoesRepository avaliacoesRepository;
  final AuthProvider authProvider;

  PontoDetalheStatus _status = PontoDetalheStatus.carregando;
  Ponto? _ponto;
  List<Avaliacao> _primeirasAvaliacoes = const [];
  int _totalAvaliacoes = 0;
  Avaliacao? _minhaAvaliacao;
  String? _mensagemErro;
  String? _pontoId;

  PontoDetalheStatus get status => _status;
  Ponto? get ponto => _ponto;
  List<Avaliacao> get primeirasAvaliacoes => _primeirasAvaliacoes;
  int get totalAvaliacoes => _totalAvaliacoes;
  Avaliacao? get minhaAvaliacao => _minhaAvaliacao;
  String? get mensagemErro => _mensagemErro;

  Future<void> carregar(String pontoId) async {
    _pontoId = pontoId;
    _status = PontoDetalheStatus.carregando;
    _mensagemErro = null;
    notifyListeners();

    final logado = authProvider.usuario != null;

    Ponto? ponto;
    String? erroPonto;
    List<Avaliacao> avaliacoes = const [];
    Avaliacao? minha;

    Future<void> carregarPonto() async {
      try {
        ponto = await pontosRepository.buscarPorId(pontoId);
      } on PontosException catch (e) {
        erroPonto = e.message;
      }
    }

    Future<void> carregarAvaliacoes() async {
      try {
        avaliacoes = await avaliacoesRepository.listar(
          pontoId,
          pagina: 1,
          porPagina: 5,
        );
      } on AvaliacoesException {
        avaliacoes = const [];
      }
    }

    Future<void> carregarMinha() async {
      if (!logado) return;
      try {
        minha = await avaliacoesRepository.minhaAvaliacao(pontoId);
      } on AvaliacoesException {
        minha = null;
      }
    }

    await Future.wait([carregarPonto(), carregarAvaliacoes(), carregarMinha()]);

    if (pontoId != _pontoId) return;

    if (erroPonto != null) {
      _status = PontoDetalheStatus.erro;
      _mensagemErro = erroPonto;
      notifyListeners();
      return;
    }

    _ponto = ponto;
    _primeirasAvaliacoes = avaliacoes;
    _totalAvaliacoes = ponto!.totalAvaliacoes;
    _minhaAvaliacao = minha;
    _status = PontoDetalheStatus.sucesso;
    notifyListeners();
  }

  Future<void> recarregar() async {
    final pontoId = _pontoId;
    if (pontoId == null) return;
    await carregar(pontoId);
  }

  /// Aplica localmente o resultado de criar/editar avaliação (chamado pelo
  /// [AvaliarProvider] após salvar com sucesso), para feedback instantâneo,
  /// e sincroniza avgNota/totalAvaliacoes em segundo plano (recalculados no
  /// backend via trigger).
  void aplicarNovaAvaliacao(Avaliacao avaliacao) {
    final eraNova = _minhaAvaliacao == null;
    _minhaAvaliacao = avaliacao;

    final lista = List<Avaliacao>.of(_primeirasAvaliacoes);
    final indice = lista.indexWhere((a) => a.id == avaliacao.id);
    if (indice != -1) {
      lista[indice] = avaliacao;
    } else {
      lista.insert(0, avaliacao);
      if (lista.length > 5) lista.removeLast();
    }
    _primeirasAvaliacoes = lista;

    if (eraNova) _totalAvaliacoes++;
    notifyListeners();

    recarregar();
  }

  /// Aplica localmente a remoção da minha avaliação (chamado pelo
  /// [AvaliarProvider] após deletar com sucesso).
  void removerMinhaAvaliacao() {
    final minha = _minhaAvaliacao;
    if (minha == null) return;

    _minhaAvaliacao = null;
    _primeirasAvaliacoes = _primeirasAvaliacoes
        .where((a) => a.id != minha.id)
        .toList();
    _totalAvaliacoes = _totalAvaliacoes > 0 ? _totalAvaliacoes - 1 : 0;
    notifyListeners();

    recarregar();
  }
}
