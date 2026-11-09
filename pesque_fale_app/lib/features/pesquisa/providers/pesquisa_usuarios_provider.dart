import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/pontos_exceptions.dart';
import '../data/usuarios_busca_repository.dart';
import '../domain/usuario_resumo.dart';

enum PesquisaUsuariosStatus { idle, carregando, sucesso, vazio, erro }

class PesquisaUsuariosProvider extends ChangeNotifier {
  PesquisaUsuariosProvider({required this.repository});

  final UsuariosBuscaRepository repository;

  static const _debounceDuration = Duration(milliseconds: 400);

  PesquisaUsuariosStatus _status = PesquisaUsuariosStatus.idle;
  List<UsuarioResumo> _usuarios = const [];
  String _buscaAtual = '';
  String? _mensagemErro;

  Timer? _debounceTimer;
  int _buscaSeq = 0;

  PesquisaUsuariosStatus get status => _status;
  List<UsuarioResumo> get usuarios => _usuarios;
  String get buscaAtual => _buscaAtual;
  String? get mensagemErro => _mensagemErro;

  void alterarBusca(String texto) {
    _buscaAtual = texto;
    _debounceTimer?.cancel();

    if (texto.trim().isEmpty) {
      _status = PesquisaUsuariosStatus.idle;
      _usuarios = const [];
      notifyListeners();
      return;
    }

    final seq = ++_buscaSeq;
    _debounceTimer = Timer(_debounceDuration, () => _buscar(texto, seq));
  }

  Future<void> recarregar() async {
    if (_buscaAtual.trim().isEmpty) return;
    await _buscar(_buscaAtual, ++_buscaSeq);
  }

  Future<void> _buscar(String texto, int seq) async {
    _status = PesquisaUsuariosStatus.carregando;
    _mensagemErro = null;
    notifyListeners();

    try {
      final resultado = await repository.buscar(texto);
      if (seq != _buscaSeq) return;

      _usuarios = resultado;
      _status = resultado.isEmpty
          ? PesquisaUsuariosStatus.vazio
          : PesquisaUsuariosStatus.sucesso;
    } on PontosException catch (e) {
      if (seq != _buscaSeq) return;
      _mensagemErro = e.message;
      _status = PesquisaUsuariosStatus.erro;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
