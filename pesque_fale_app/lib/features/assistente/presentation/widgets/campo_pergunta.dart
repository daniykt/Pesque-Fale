import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class CampoPergunta extends StatefulWidget {
  const CampoPergunta({
    super.key,
    required this.habilitado,
    required this.onEnviar,
  });

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
    _controller.clear();
    widget.onEnviar(texto);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

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
                maxLength: 500,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviar(),
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Escreva sua pergunta',
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
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