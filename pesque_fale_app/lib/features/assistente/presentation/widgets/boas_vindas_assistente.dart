import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'mascote_pira.dart';

class BoasVindasAssistente extends StatelessWidget {
  const BoasVindasAssistente({
    super.key,
    required this.sugestoes,
    required this.onSugestao,
  });

  final List<String> sugestoes;
  final ValueChanged<String> onSugestao;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Center(child: MascotePira(tamanho: 96)),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Olá! Eu sou o ${MascotePira.nome} e ajudo você a usar o Pesque & Fale.',
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Toque em uma pergunta abaixo ou escreva a sua.',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            fontSize: 17,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final sugestao in sugestoes)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: OutlinedButton(
              onPressed: () => onSugestao(sugestao),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.border),
                textStyle: const TextStyle(fontSize: 17),
              ),
              child: Text(sugestao),
            ),
          ),
      ],
    );
  }
}