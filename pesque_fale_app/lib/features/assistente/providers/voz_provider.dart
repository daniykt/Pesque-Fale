import 'package:flutter/foundation.dart';

import '../data/servico_voz.dart';
import '../domain/mensagem_assistente.dart';

class VozProvider extends ChangeNotifier {
  VozProvider({required this.servico});

  static const avisoMicrofone =
      'Não consegui usar o microfone. Confira se o app tem permissão para usar o microfone.';
  static const avisoLeitura = 'Não consegui ler a resposta em voz alta.';

  final ServicoVoz servico;

  bool _ouvindo = false;
  MensagemAssistente? _lendo;
  String? _aviso;
  bool _descartado = false;

  bool get ouvindo => _ouvindo;
  String? get aviso => _aviso;

  bool estaLendo(MensagemAssistente mensagem) => identical(_lendo, mensagem);

  Future<void> alternarEscuta(ValueChanged<String> onTexto) async {
    if (_ouvindo) {
      await pararEscuta();
      return;
    }

    await pararLeitura();
    _aviso = null;
    _ouvindo = true;
    _notificar();

    final iniciou = await servico.iniciarEscuta(
      onTexto: (texto) {
        if (!_descartado) onTexto(texto);
      },
      onFim: () {
        if (!_ouvindo) return;
        _ouvindo = false;
        _notificar();
      },
    );

    if (!iniciou) {
      _ouvindo = false;
      _aviso = avisoMicrofone;
      _notificar();
    }
  }

  Future<void> pararEscuta() async {
    if (!_ouvindo) return;
    _ouvindo = false;
    _notificar();
    await servico.pararEscuta();
  }

  Future<void> alternarLeitura(MensagemAssistente mensagem) async {
    if (estaLendo(mensagem)) {
      await pararLeitura();
      return;
    }

    await pararEscuta();
    await servico.pararLeitura();
    _aviso = null;
    _lendo = mensagem;
    _notificar();

    final leu = await servico.ler(
      _textoParaLer(mensagem.texto),
      onFim: () {
        if (!estaLendo(mensagem)) return;
        _lendo = null;
        _notificar();
      },
    );

    if (!leu && estaLendo(mensagem)) {
      _lendo = null;
      _aviso = avisoLeitura;
      _notificar();
    }
  }

  Future<void> pararLeitura() async {
    if (_lendo == null) return;
    _lendo = null;
    _notificar();
    await servico.pararLeitura();
  }

  String _textoParaLer(String texto) =>
      texto.replaceAll(RegExp(r'[*_#`]'), '').trim();

  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    servico.pararEscuta();
    servico.pararLeitura();
    super.dispose();
  }
}