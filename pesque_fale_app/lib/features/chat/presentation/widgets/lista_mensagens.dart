import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatador_data_conversa.dart';
import '../../domain/mensagem.dart';
import 'bolha_mensagem.dart';
import 'divisor_data.dart';
import 'indicador_digitando.dart';

class ListaMensagens extends StatefulWidget {
  const ListaMensagens({
    super.key,
    required this.mensagens,
    required this.usuarioLogadoId,
    required this.outroDigitando,
  });

  final List<Mensagem> mensagens;
  final String usuarioLogadoId;
  final bool outroDigitando;

  @override
  State<ListaMensagens> createState() => _ListaMensagensState();
}

class _ListaMensagensState extends State<ListaMensagens> {
  static const _formatador = FormatadorDataConversa();
  static const _limiarPertoDoFim = 150.0;

  final _controller = ScrollController();
  bool _pertoDoFim = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_atualizarPertoDoFim);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _irParaFim(animado: false),
    );
  }

  @override
  void didUpdateWidget(covariant ListaMensagens oldWidget) {
    super.didUpdateWidget(oldWidget);
    final chegouMensagemNova =
        widget.mensagens.length > oldWidget.mensagens.length;
    // Só acompanha o fim se o usuário já estava lendo as mensagens recentes —
    // não interrompe quem rolou pra cima pra ler o histórico.
    if (chegouMensagemNova && _pertoDoFim) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _irParaFim());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_atualizarPertoDoFim);
    _controller.dispose();
    super.dispose();
  }

  void _atualizarPertoDoFim() {
    if (!_controller.hasClients) return;
    final distancia =
        _controller.position.maxScrollExtent - _controller.position.pixels;
    _pertoDoFim = distancia < _limiarPertoDoFim;
  }

  void _irParaFim({bool animado = true}) {
    if (!_controller.hasClients) return;
    final destino = _controller.position.maxScrollExtent;
    if (animado) {
      _controller.animateTo(
        destino,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _controller.jumpTo(destino);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itens = _construirItens();

    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      itemCount: itens.length,
      itemBuilder: (context, i) => itens[i],
    );
  }

  List<Widget> _construirItens() {
    final itens = <Widget>[];
    DateTime? diaAnterior;

    for (final m in widget.mensagens) {
      final dia = DateTime(m.criadoEm.year, m.criadoEm.month, m.criadoEm.day);
      if (diaAnterior == null || dia != diaAnterior) {
        itens.add(
          DivisorData(texto: _formatador.formatarDivisorData(m.criadoEm)),
        );
        diaAnterior = dia;
      }
      itens.add(
        BolhaMensagem(
          mensagem: m,
          ehMinha: m.userId == widget.usuarioLogadoId,
        ),
      );
    }

    if (widget.outroDigitando) {
      itens.add(const IndicadorDigitando());
    }

    return itens;
  }
}
