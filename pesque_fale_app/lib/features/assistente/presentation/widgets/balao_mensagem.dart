import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/mensagem_assistente.dart';

class BalaoMensagem extends StatelessWidget {
  const BalaoMensagem({
    super.key,
    required this.mensagem,
    required this.onAcao,
  });

  final MensagemAssistente mensagem;
  final ValueChanged<AcaoAssistente> onAcao;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final doUsuario = mensagem.doUsuario;
    final estiloTexto = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontSize: 18,
      height: 1.4,
      color: doUsuario ? Colors.white : colors.textPrimary,
    );

    return Align(
      alignment: doUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: doUsuario
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Semantics(
             label: doUsuario ? 'Você disse' : 'Pirá respondeu',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: doUsuario ? colors.primary : colors.surfaceVariant,
                  borderRadius: AppRadius.lgRadius,
                ),
                child: Text(mensagem.texto, style: estiloTexto),
              ),
            ),
            for (final acao in mensagem.acoes)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: OutlinedButton.icon(
                  onPressed: () => onAcao(acao),
                  icon: Icon(
                    acao.tipo == TipoAcaoAssistente.abrirLocal
                        ? Icons.place_outlined
                        : Icons.arrow_forward,
                  ),
                  label: Text(acao.rotulo),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    foregroundColor: colors.primaryAccent,
                    side: BorderSide(color: colors.primaryAccent),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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