import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/sobre_conteudo.dart';
import 'sobre_titulo_secao.dart';

class SobreTime extends StatelessWidget {
  const SobreTime({super.key, required this.membros});

  final List<MembroTime> membros;

  static const int _colunas = 2;

  @override
  Widget build(BuildContext context) {
    // Linhas de altura natural em vez de grid com proporção fixa: o card
    // cresce com a fonte do sistema sem estourar em telas estreitas.
    final linhas = <Widget>[];
    for (var i = 0; i < membros.length; i += _colunas) {
      if (i > 0) linhas.add(const SizedBox(height: AppSpacing.xs));
      linhas.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = i; j < i + _colunas; j++) ...[
                if (j > i) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: j < membros.length
                      ? _CardMembro(membro: membros[j])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SobreTituloSecao('O time'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(children: linhas),
        ),
      ],
    );
  }
}

class _CardMembro extends StatelessWidget {
  const _CardMembro({required this.membro});

  final MembroTime membro;

  static const double _avatarRaio = 18;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.mdRadius,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: _avatarRaio,
            backgroundImage: AssetImage(membro.fotoAsset),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  membro.nome,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  membro.funcao,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
