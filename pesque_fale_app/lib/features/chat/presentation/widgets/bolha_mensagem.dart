import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatador_data_conversa.dart';
import '../../domain/mensagem.dart';

class BolhaMensagem extends StatelessWidget {
  const BolhaMensagem({super.key, required this.mensagem, required this.ehMinha});

  final Mensagem mensagem;
  final bool ehMinha;

  static const _formatador = FormatadorDataConversa();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final corTexto = ehMinha ? Colors.white : colors.textPrimary;

    return Align(
      alignment: ehMinha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ehMinha ? colors.primary : colors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(ehMinha ? 16 : 4),
            bottomRight: Radius.circular(ehMinha ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mensagem.texto, style: TextStyle(color: corTexto)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatador.formatarHora(mensagem.criadoEm),
                  style: TextStyle(
                    color: corTexto.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
                if (ehMinha) ...[
                  const SizedBox(width: 4),
                  Icon(
                    mensagem.status == StatusMensagem.visto
                        ? Icons.done_all
                        : Icons.done,
                    size: 14,
                    color: mensagem.status == StatusMensagem.visto
                        ? Colors.lightBlueAccent
                        : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
