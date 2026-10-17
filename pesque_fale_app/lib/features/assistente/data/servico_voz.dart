import 'package:flutter/foundation.dart';

abstract class ServicoVoz {
  Future<bool> iniciarEscuta({
    required ValueChanged<String> onTexto,
    required VoidCallback onFim,
  });

  Future<void> pararEscuta();

  Future<bool> ler(String texto, {required VoidCallback onFim});

  Future<void> pararLeitura();
}