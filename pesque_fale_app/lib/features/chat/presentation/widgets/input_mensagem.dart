import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

const _limiteCaracteres = 500;

class InputMensagem extends StatefulWidget {
  const InputMensagem({
    super.key,
    required this.onEnviar,
    required this.onDigitando,
  });

  final ValueChanged<String> onEnviar;
  final ValueChanged<String> onDigitando;

  @override
  State<InputMensagem> createState() => _InputMensagemState();
}

class _InputMensagemState extends State<InputMensagem> {
  final _controller = TextEditingController();

  bool get _podeEnviar {
    final texto = _controller.text.trim();
    return texto.isNotEmpty && texto.length <= _limiteCaracteres;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!_podeEnviar) return;
    widget.onEnviar(_controller.text);
    _controller.clear();
    widget.onDigitando('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _controller,
                    maxLength: _limiteCaracteres,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    onChanged: (texto) {
                      widget.onDigitando(texto);
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Digite uma mensagem...',
                      filled: true,
                      fillColor: colors.surfaceVariant,
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.lgRadius,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 4),
                    child: Text(
                      '${_controller.text.length}/$_limiteCaracteres',
                      style: TextStyle(
                        fontSize: 11,
                        color: _controller.text.length > _limiteCaracteres
                            ? colors.danger
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Opacity(
                opacity: _podeEnviar ? 1 : 0.4,
                child: InkWell(
                  onTap: _podeEnviar ? _enviar : null,
                  borderRadius: AppRadius.pillRadius,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
