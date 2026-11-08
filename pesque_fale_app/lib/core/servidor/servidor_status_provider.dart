import 'dart:async';

import 'package:flutter/foundation.dart';

import 'health_api_client.dart';

/// Situação da checagem do `GET /health`.
enum ServidorStatus { verificando, demorando, pronto, falhou }

/// O que o aviso das telas de login e cadastro deve mostrar.
enum AvisoServidor { nenhum, conectando, pronto, falhou }

/// Aquece a API ao abrir o app. O Render free hiberna e a primeira resposta
/// do dia pode levar até 1 minuto. Login e cadastro leem este mesmo estado, e
/// a checagem roda uma vez só por abertura do app (ou por "Tentar de novo").
class ServidorStatusProvider extends ChangeNotifier {
  ServidorStatusProvider({
    required HealthApiClient this.client,
    this.tempoParaAvisar = const Duration(seconds: 3),
    this.tempoLimite = const Duration(seconds: 90),
    this.timeoutPorTentativa = const Duration(seconds: 20),
    this.pausaEntreTentativas = const Duration(seconds: 2),
  }) : _status = ServidorStatus.verificando;

  /// Para o `USE_MOCK`: não chama o `/health` e já nasce pronto.
  ServidorStatusProvider.pronto()
    : client = null,
      _status = ServidorStatus.pronto,
      tempoParaAvisar = Duration.zero,
      tempoLimite = Duration.zero,
      timeoutPorTentativa = Duration.zero,
      pausaEntreTentativas = Duration.zero;

  final HealthApiClient? client;

  /// Sem resposta até aqui, o aviso aparece.
  final Duration tempoParaAvisar;

  /// Sem resposta até aqui, a checagem desiste.
  final Duration tempoLimite;
  final Duration timeoutPorTentativa;
  final Duration pausaEntreTentativas;

  ServidorStatus _status;
  int _segundos = 0;
  bool _avisoAberto = false;
  bool _mostrandoPronto = false;
  bool _iniciado = false;
  bool _descartado = false;
  int _ciclo = 0;
  Completer<bool>? _espera;
  Timer? _relogio;
  Timer? _prazo;
  Timer? _timerPronto;

  ServidorStatus get status => _status;

  /// Segundos desde o início da checagem atual.
  int get segundosDecorridos => _segundos;

  AvisoServidor get aviso {
    switch (_status) {
      case ServidorStatus.verificando:
        return _avisoAberto ? AvisoServidor.conectando : AvisoServidor.nenhum;
      case ServidorStatus.demorando:
        return AvisoServidor.conectando;
      case ServidorStatus.pronto:
        return _mostrandoPronto ? AvisoServidor.pronto : AvisoServidor.nenhum;
      case ServidorStatus.falhou:
        return AvisoServidor.falhou;
    }
  }

  /// Dispara a checagem. Chamadas seguintes não fazem nada.
  void iniciar() {
    if (client == null || _iniciado) return;
    _iniciado = true;
    _comecar();
  }

  /// Reinicia a checagem e o contador depois de [ServidorStatus.falhou].
  void tentarDeNovo() {
    if (client == null || _status != ServidorStatus.falhou) return;
    // O aviso já estava na tela: segue visível em "Conectando…".
    _avisoAberto = true;
    _comecar();
  }

  /// `true` quando o servidor fica pronto, `false` se a checagem falhar.
  /// Já pronto, devolve `true` na hora; já em falha, `false` na hora.
  Future<bool> aguardarPronto() {
    if (_status == ServidorStatus.pronto) return Future.value(true);
    if (_status == ServidorStatus.falhou) return Future.value(false);
    iniciar();
    return _espera!.future;
  }

  void _comecar() {
    _cancelarTimers();
    final ciclo = ++_ciclo;
    _status = ServidorStatus.verificando;
    _segundos = 0;
    _mostrandoPronto = false;
    _espera = Completer<bool>();
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) => _tique());
    _prazo = Timer(tempoLimite, () => _falhar(ciclo));
    notifyListeners();
    _checar(ciclo);
  }

  void _tique() {
    _segundos++;
    if (_status == ServidorStatus.verificando &&
        Duration(seconds: _segundos) >= tempoParaAvisar) {
      _status = ServidorStatus.demorando;
      _avisoAberto = true;
    }
    // Só notifica quando o contador está na tela.
    if (aviso == AvisoServidor.conectando) notifyListeners();
  }

  bool _cicloAtivo(int ciclo) =>
      !_descartado &&
      ciclo == _ciclo &&
      (_status == ServidorStatus.verificando ||
          _status == ServidorStatus.demorando);

  Future<void> _checar(int ciclo) async {
    while (_cicloAtivo(ciclo)) {
      bool ok;
      try {
        ok = await client!.checar(timeout: timeoutPorTentativa);
      } catch (_) {
        // Rede fora, timeout ou servidor ainda subindo: tenta de novo até o
        // prazo total acabar.
        ok = false;
      }
      if (!_cicloAtivo(ciclo)) return;
      if (ok) {
        _ficarPronto();
        return;
      }
      await Future<void>.delayed(pausaEntreTentativas);
    }
  }

  void _ficarPronto() {
    _cancelarTimers();
    _status = ServidorStatus.pronto;
    if (_avisoAberto) {
      _avisoAberto = false;
      _mostrandoPronto = true;
      _timerPronto = Timer(const Duration(seconds: 2), () {
        _mostrandoPronto = false;
        if (!_descartado) notifyListeners();
      });
    }
    _espera?.complete(true);
    notifyListeners();
  }

  void _falhar(int ciclo) {
    if (!_cicloAtivo(ciclo)) return;
    _cancelarTimers();
    _status = ServidorStatus.falhou;
    _espera?.complete(false);
    notifyListeners();
  }

  void _cancelarTimers() {
    _relogio?.cancel();
    _prazo?.cancel();
    _timerPronto?.cancel();
  }

  @override
  void dispose() {
    _descartado = true;
    _cancelarTimers();
    super.dispose();
  }
}
