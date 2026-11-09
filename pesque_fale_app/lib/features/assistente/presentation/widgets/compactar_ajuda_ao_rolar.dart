import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Observa a rolagem vertical feita pelo usuário em [child] e informa ao
/// [builder] se o botão de Ajuda deve ficar compacto: rolar para baixo
/// (conteúdo subindo) compacta, rolar para cima expande. Rolagens
/// horizontais (abas, carrosséis) são ignoradas. Trocar [abaAtual] volta ao
/// botão expandido.
class CompactarAjudaAoRolar extends StatefulWidget {
  const CompactarAjudaAoRolar({
    super.key,
    required this.abaAtual,
    required this.builder,
  });

  final int abaAtual;
  final Widget Function(BuildContext context, bool compacto) builder;

  @override
  State<CompactarAjudaAoRolar> createState() => _CompactarAjudaAoRolarState();
}

class _CompactarAjudaAoRolarState extends State<CompactarAjudaAoRolar> {
  bool _compacto = false;

  @override
  void didUpdateWidget(CompactarAjudaAoRolar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.abaAtual != oldWidget.abaAtual) _compacto = false;
  }

  bool _aoRolar(UserScrollNotification notificacao) {
    if (notificacao.metrics.axis != Axis.vertical) return false;

    final compacto = switch (notificacao.direction) {
      ScrollDirection.reverse => true,
      ScrollDirection.forward => false,
      ScrollDirection.idle => _compacto,
    };
    if (compacto != _compacto) setState(() => _compacto = compacto);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<UserScrollNotification>(
      onNotification: _aoRolar,
      child: widget.builder(context, _compacto),
    );
  }
}
