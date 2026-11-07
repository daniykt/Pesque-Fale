import 'package:flutter/foundation.dart';

import '../data/clima_exceptions.dart';
import '../data/clima_repository.dart';
import '../data/localizacao_service.dart';
import '../domain/clima.dart';

enum StatusClima { inicial, carregando, sucesso, semLocalizacao, erro }

class ClimaProvider extends ChangeNotifier {
  ClimaProvider({
    required this.repository,
    required this.localizacao,
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now;

  final ClimaRepository repository;
  final LocalizacaoService localizacao;
  final DateTime Function() _agora;

  static const validadeDoClima = Duration(minutes: 10);

  StatusClima _status = StatusClima.inicial;
  Clima? _clima;
  MotivoSemLocalizacao? _motivo;
  String? _mensagemErro;
  Future<void>? _emVoo;
  DateTime? _buscadoEm;

  StatusClima get status => _status;
  Clima? get clima => _clima;
  MotivoSemLocalizacao? get motivoSemLocalizacao => _motivo;
  String? get mensagemErro => _mensagemErro;
  DateTime get hoje => _agora();

  Future<void> abrir() async {
    final buscadoEm = _buscadoEm;
    if (_status == StatusClima.sucesso &&
        buscadoEm != null &&
        _agora().difference(buscadoEm) < validadeDoClima) {
      return;
    }
    await _carregar(pedirPermissao: _status == StatusClima.inicial);
  }

  Future<void> atualizar() => _carregar(pedirPermissao: false);

  Future<void> permitirLocalizacao() async {
    final motivo = _motivo;
    if (motivo != null && motivo != MotivoSemLocalizacao.negada) {
      await localizacao.abrirConfiguracoes(motivo);
    }
    await _carregar(pedirPermissao: true);
  }

  Future<void> _carregar({required bool pedirPermissao}) {
    return _emVoo ??= _buscar(pedirPermissao).whenComplete(() {
      _emVoo = null;
    });
  }

  Future<void> _buscar(bool pedirPermissao) async {
    _status = StatusClima.carregando;
    _mensagemErro = null;
    notifyListeners();

    try {
      final resultado = await localizacao.obter(pedirPermissao: pedirPermissao);
      switch (resultado) {
        case LocalizacaoIndisponivel(:final motivo):
          _clima = null;
          _motivo = motivo;
          _status = StatusClima.semLocalizacao;
        case LocalizacaoObtida(:final latitude, :final longitude):
          _motivo = null;
          _clima = await repository.buscarAtual(
            latitude: latitude,
            longitude: longitude,
          );
          _buscadoEm = _agora();
          _status = StatusClima.sucesso;
      }
    } on ClimaException catch (e) {
      _falhar(e.message);
    } catch (_) {
      _falhar('Não foi possível obter o clima agora.');
    }
    notifyListeners();
  }

  void _falhar(String mensagem) {
    _clima = null;
    _buscadoEm = null;
    _mensagemErro = mensagem;
    _status = StatusClima.erro;
  }
}
