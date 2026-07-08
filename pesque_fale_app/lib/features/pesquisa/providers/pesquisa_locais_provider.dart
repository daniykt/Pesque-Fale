import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../data/pontos_exceptions.dart';
import '../data/pontos_repository.dart';
import '../domain/avaliacao_min_filtro.dart';
import '../domain/filtros_locais.dart';
import '../domain/ponto.dart';
import '../domain/tipo_ponto.dart';

enum PesquisaLocaisStatus { idle, carregando, sucesso, vazio, erro }

enum ModoLocais { lista, mapa }

class PesquisaLocaisProvider extends ChangeNotifier {
  PesquisaLocaisProvider({required this.repository});

  final PontosRepository repository;

  static const _debounceDuration = Duration(milliseconds: 400);

  PesquisaLocaisStatus _status = PesquisaLocaisStatus.idle;
  List<Ponto> _pontos = const [];
  FiltrosLocais _filtros = const FiltrosLocais();
  ModoLocais _modo = ModoLocais.lista;
  Position? _posicaoUsuario;
  bool _localizacaoNegada = false;
  String? _mensagemErro;
  String? _pontoDestacadoId;

  Timer? _debounceTimer;
  int _buscaSeq = 0;

  PesquisaLocaisStatus get status => _status;
  List<Ponto> get pontos => _pontos;
  FiltrosLocais get filtros => _filtros;
  ModoLocais get modo => _modo;
  Position? get posicaoUsuario => _posicaoUsuario;
  bool get localizacaoNegada => _localizacaoNegada;
  String? get mensagemErro => _mensagemErro;
  String? get pontoDestacadoId => _pontoDestacadoId;

  Future<void> inicializar() => _buscar();

  void alterarBusca(String texto) {
    _filtros = _filtros.copyWith(busca: texto);
    _debounceTimer?.cancel();
    final seq = ++_buscaSeq;
    _debounceTimer = Timer(_debounceDuration, () => _buscar(seq: seq));
  }

  void alterarTipo(TipoPonto? novo) {
    _filtros = _filtros.copyWith(tipo: () => novo);
    _buscar();
  }

  void alterarAvaliacaoMin(AvaliacaoMinFiltro nova) {
    _filtros = _filtros.copyWith(avaliacaoMin: nova);
    _buscar();
  }

  void alterarRaio(double km) {
    if (_modo != ModoLocais.mapa) return;
    _filtros = _filtros.copyWith(raioKm: km);
    _debounceTimer?.cancel();
    final seq = ++_buscaSeq;
    _debounceTimer = Timer(_debounceDuration, () => _buscar(seq: seq));
  }

  Future<void> alterarModo(ModoLocais novo) async {
    if (novo == _modo) return;

    if (novo == ModoLocais.mapa && _posicaoUsuario == null) {
      final posicao = await _obterLocalizacao();
      if (posicao == null) {
        _localizacaoNegada = true;
        _modo = ModoLocais.lista;
        notifyListeners();
        return;
      }
      _posicaoUsuario = posicao;
      _localizacaoNegada = false;
    }

    _modo = novo;
    await _buscar();
  }

  void destacarPonto(String? id) {
    _pontoDestacadoId = id;
    notifyListeners();
  }

  /// Chamado a partir da tela de detalhe ("Ver no mapa"): muda para o modo
  /// Mapa, garante que o ponto esteja na lista exibida e o destaca.
  void focarPonto(Ponto ponto) {
    _modo = ModoLocais.mapa;
    if (!_pontos.any((p) => p.id == ponto.id)) {
      _pontos = [..._pontos, ponto];
    }
    _pontoDestacadoId = ponto.id;
    notifyListeners();
  }

  Future<void> recarregar() => _buscar();

  Future<Position?> _obterLocalizacao() async {
    try {
      final servicoAtivo = await Geolocator.isLocationServiceEnabled();
      if (!servicoAtivo) return null;

      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _buscar({int? seq}) async {
    final buscaSeq = seq ?? ++_buscaSeq;

    _status = PesquisaLocaisStatus.carregando;
    _mensagemErro = null;
    notifyListeners();

    try {
      final incluirDistancia = _modo == ModoLocais.mapa;
      final resultado = await repository.buscar(
        filtros: _filtros,
        lat: _posicaoUsuario?.latitude,
        lng: _posicaoUsuario?.longitude,
        incluirDistancia: incluirDistancia,
      );
      if (buscaSeq != _buscaSeq) return;

      _pontos = resultado;
      _status = resultado.isEmpty
          ? PesquisaLocaisStatus.vazio
          : PesquisaLocaisStatus.sucesso;
    } on PontosException catch (e) {
      if (buscaSeq != _buscaSeq) return;
      _mensagemErro = e.message;
      _status = PesquisaLocaisStatus.erro;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
