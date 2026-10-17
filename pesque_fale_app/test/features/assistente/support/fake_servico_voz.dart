import 'package:flutter/foundation.dart';
import 'package:pesque_fale_app/features/assistente/data/servico_voz.dart';

class FakeServicoVoz implements ServicoVoz {
  bool microfoneLiberado = true;
  bool leituraFunciona = true;
  ValueChanged<String>? onTexto;
  VoidCallback? onFimEscuta;
  VoidCallback? onFimLeitura;
  final List<String> lidos = [];
  int escutasIniciadas = 0;
  int paradasEscuta = 0;
  int paradasLeitura = 0;

  @override
  Future<bool> iniciarEscuta({
    required ValueChanged<String> onTexto,
    required VoidCallback onFim,
  }) async {
    if (!microfoneLiberado) return false;
    escutasIniciadas++;
    this.onTexto = onTexto;
    onFimEscuta = onFim;
    return true;
  }

  @override
  Future<void> pararEscuta() async {
    paradasEscuta++;
    final onFim = onFimEscuta;
    onFimEscuta = null;
    onFim?.call();
  }

  @override
  Future<bool> ler(String texto, {required VoidCallback onFim}) async {
    if (!leituraFunciona) return false;
    lidos.add(texto);
    onFimLeitura = onFim;
    return true;
  }

  @override
  Future<void> pararLeitura() async {
    paradasLeitura++;
    final onFim = onFimLeitura;
    onFimLeitura = null;
    onFim?.call();
  }

  void terminarEscuta() {
    final onFim = onFimEscuta;
    onFimEscuta = null;
    onFim?.call();
  }

  void terminarLeitura() {
    final onFim = onFimLeitura;
    onFimLeitura = null;
    onFim?.call();
  }
}