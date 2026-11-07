import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'mascote_pira.dart';

/// Botão flutuante que abre o assistente. Em [compacto] vira um círculo de
/// 56 px só com o mascote (o [Tooltip] passa a ser o rótulo acessível).
class BotaoAjudaAssistente extends StatelessWidget {
  const BotaoAjudaAssistente({super.key, this.compacto = false});

  final bool compacto;

  /// Espaço no fim das listas para o último item não ficar embaixo do
  /// botão: 56 do FAB + 16 de margem + folga.
  static const double espacoInferiorListas = AppSpacing.xxl + AppSpacing.xl;

  static const double _tamanhoMascote = 28;
  static const double _tamanhoCompacto = 56;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    // Alinhado ao início para o mascote ficar parado enquanto o rótulo
    // aparece/some, com o botão em qualquer canto da tela.
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: AlignmentDirectional.centerStart,
      child: FloatingActionButton.extended(
        heroTag: 'botao-ajuda-assistente',
        tooltip: 'Abrir o ${MascotePira.nome}, assistente virtual',
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        isExtended: !compacto,
        extendedPadding: compacto
            ? const EdgeInsets.symmetric(
                horizontal: (_tamanhoCompacto - _tamanhoMascote) / 2,
              )
            : null,
        onPressed: () => Navigator.of(context).pushNamed('/assistente'),
        // O desenho do mascote não é quadrado: o slot fixo garante o
        // círculo de 56 px no modo compacto.
        icon: const SizedBox.square(
          dimension: _tamanhoMascote,
          child: Center(
            child: MascotePira(tamanho: _tamanhoMascote, cor: Colors.white),
          ),
        ),
        label: const Text(
          'Ajuda',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
