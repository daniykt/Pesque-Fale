import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'servico_voz.dart';

class ServicoVozDispositivo implements ServicoVoz {
  static const _idioma = 'pt-BR';

  SpeechToText? _reconhecedor;
  bool _reconhecedorPronto = false;
  VoidCallback? _onFimEscuta;

  FlutterTts? _leitor;
  VoidCallback? _onFimLeitura;

  @override
  Future<bool> iniciarEscuta({
    required ValueChanged<String> onTexto,
    required VoidCallback onFim,
  }) async {
    try {
      final reconhecedor = await _prepararReconhecedor();
      if (reconhecedor == null) return false;

      _onFimEscuta = onFim;
      await reconhecedor.listen(
        onResult: (SpeechRecognitionResult resultado) {
          onTexto(resultado.recognizedWords);
          if (resultado.finalResult) _encerrarEscuta();
        },
        listenOptions: SpeechListenOptions(
          localeId: _idioma,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4),
        ),
      );
      return true;
    } catch (erro) {
      _onFimEscuta = null;
      debugPrint('Falha no microfone do assistente: $erro');
      return false;
    }
  }

  @override
  Future<void> pararEscuta() async {
    final reconhecedor = _reconhecedor;
    if (reconhecedor != null && _reconhecedorPronto) {
      await _ignorarFalha(() => reconhecedor.stop());
    }
    _encerrarEscuta();
  }

  @override
  Future<bool> ler(String texto, {required VoidCallback onFim}) async {
    try {
      final leitor = await _prepararLeitor();
      _onFimLeitura = onFim;
      await leitor.speak(texto);
      return true;
    } catch (erro) {
      _onFimLeitura = null;
      debugPrint('Falha na leitura do assistente: $erro');
      return false;
    }
  }

  @override
  Future<void> pararLeitura() async {
    final leitor = _leitor;
    _onFimLeitura = null;
    if (leitor == null) return;
    await _ignorarFalha(() => leitor.stop());
  }

  Future<SpeechToText?> _prepararReconhecedor() async {
    final reconhecedor = _reconhecedor ??= SpeechToText();
    if (!_reconhecedorPronto) {
      _reconhecedorPronto = await reconhecedor.initialize(
        onStatus: _aoMudarStatus,
        onError: _aoFalharEscuta,
      );
    }
    return _reconhecedorPronto ? reconhecedor : null;
  }

  Future<FlutterTts> _prepararLeitor() async {
    final existente = _leitor;
    if (existente != null) return existente;

    final leitor = FlutterTts();
    leitor.setCompletionHandler(_encerrarLeitura);
    leitor.setCancelHandler(_encerrarLeitura);
    leitor.setErrorHandler((_) => _encerrarLeitura());
    await leitor.setLanguage(_idioma);
    await leitor.setSpeechRate(kIsWeb ? 0.9 : 0.45);
    _leitor = leitor;
    return leitor;
  }

  void _aoMudarStatus(String status) {
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _encerrarEscuta();
    }
  }

  void _aoFalharEscuta(SpeechRecognitionError erro) {
    debugPrint('Erro no reconhecimento de voz: ${erro.errorMsg}');
    _encerrarEscuta();
  }

  void _encerrarEscuta() {
    final onFim = _onFimEscuta;
    _onFimEscuta = null;
    onFim?.call();
  }

  void _encerrarLeitura() {
    final onFim = _onFimLeitura;
    _onFimLeitura = null;
    onFim?.call();
  }

  Future<void> _ignorarFalha(Future<void> Function() acao) async {
    try {
      await acao();
    } catch (erro) {
      debugPrint('Falha na voz do assistente: $erro');
    }
  }
}