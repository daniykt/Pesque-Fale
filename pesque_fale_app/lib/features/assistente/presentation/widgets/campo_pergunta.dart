import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../providers/voz_provider.dart';

class CampoPergunta extends StatefulWidget {
  const CampoPergunta({
    super.key,
    required this.habilitado,
    required this.onEnviar,
  });

  static const tamanhoMaximo = 500;

  final bool habilitado;
  final ValueChanged<String> onEnviar;

  @override
  State<CampoPergunta> createState() => _CampoPerguntaState();
}

class _CampoPerguntaState extends State<CampoPergunta> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _controller.text.trim();
    if (texto.isEmpty || !widget.habilitado) return;
    final voz = context.read<VozProvider>();
    voz.pararEscuta();
    voz.pararLeitura();
    _controller.clear();
    widget.onEnviar(texto);
  }

  void _receberTextoFalado(String texto) {
    if (!mounted) return;
    final limitado = texto.length > CampoPergunta.tamanhoMaximo
        ? texto.substring(0, CampoPergunta.tamanhoMaximo)
        : texto;
    _controller.value = TextEditingValue(
      text: limitado,
      selection: TextSelection.collapsed(offset: limitado.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final voz = context.watch<VozProvider>();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLength: CampoPergunta.tamanhoMaximo,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviar(),
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: voz.ouvindo
                      ? 'Pode falar, estou ouvindo...'
                      : 'Escreva ou fale sua pergunta',
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              onPressed: () => voz.alternarEscuta(_receberTextoFalado),
              iconSize: 28,
              tooltip: voz.ouvindo ? 'Parar de ouvir' : 'Falar a pergunta',
              color: voz.ouvindo ? colors.danger : colors.primaryAccent,
              icon: Icon(voz.ouvindo ? Icons.mic : Icons.mic_none),
            ),
            IconButton.filled(
              onPressed: widget.habilitado ? _enviar : null,
              iconSize: 28,
              tooltip: 'Enviar pergunta',
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}