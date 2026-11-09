import 'package:flutter/foundation.dart';

import '../data/avaliacoes_exceptions.dart';
import '../data/avaliacoes_repository.dart';
import '../domain/avaliacao.dart';

enum AvaliacoesListaStatus { carregando, sucesso, carregandoMais, erro }

class AvaliacoesListaProvider extends ChangeNotifier {
  AvaliacoesListaProvider({required this.repository, required this.pontoId});

  final AvaliacoesRepository repository;
  final String pontoId;

  static const _porPagina = 20;

  AvaliacoesListaStatus _status = AvaliacoesListaStatus.carregando;
  List<Avaliacao> _avaliacoes = const [];
  int _pagina = 1;
  bool _temMais = true;
  String? _mensagemErro;

  AvaliacoesListaStatus get status => _status;
  List<Avaliacao> get avaliacoes => _avaliacoes;
  bool get temMais => _temMais;
  String? get mensagemErro => _mensagemErro;

  Future<void> carregar() async {
    _status = AvaliacoesListaStatus.carregando;
    _mensagemErro = null;
    notifyListeners();

    try {
      final resultado = await repository.listar(
        pontoId,
        pagina: 1,
        porPagina: _porPagina,
      );
      _avaliacoes = resultado;
      _pagina = 1;
      _temMais = resultado.length == _porPagina;
      _status = AvaliacoesListaStatus.sucesso;
    } on AvaliacoesException catch (e) {
      _mensagemErro = e.message;
      _status = AvaliacoesListaStatus.erro;
    }
    notifyListeners();
  }

  Future<void> carregarMais() async {
    if (!_temMais || _status == AvaliacoesListaStatus.carregandoMais) return;

    _status = AvaliacoesListaStatus.carregandoMais;
    notifyListeners();

    try {
      final proximaPagina = _pagina + 1;
      final resultado = await repository.listar(
        pontoId,
        pagina: proximaPagina,
        porPagina: _porPagina,
      );
      _avaliacoes = [..._avaliacoes, ...resultado];
      _pagina = proximaPagina;
      _temMais = resultado.length == _porPagina;
      _status = AvaliacoesListaStatus.sucesso;
    } on AvaliacoesException {
      _status = AvaliacoesListaStatus.sucesso;
      _temMais = false;
    }
    notifyListeners();
  }
}
