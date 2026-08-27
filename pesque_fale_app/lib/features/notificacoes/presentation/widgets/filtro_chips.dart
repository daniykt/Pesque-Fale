import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/notificacao.dart';

class FiltroChips extends StatelessWidget {
  const FiltroChips({
    super.key,
    required this.selecionado,
    required this.onSelecionar,
  });

  final TipoNotificacao? selecionado;
  final ValueChanged<TipoNotificacao?> onSelecionar;

  static const _opcoes = <MapEntry<TipoNotificacao?, String>>[
    MapEntry(null, 'Todas'),
    MapEntry(TipoNotificacao.seguindo, 'Seguidores'),
    MapEntry(TipoNotificacao.curtida, 'Curtidas'),
    MapEntry(TipoNotificacao.comentario, 'Comentários'),
    MapEntry(TipoNotificacao.mensagem, 'Mensagens'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: _opcoes.map((opcao) {
        final ativo = opcao.key == selecionado;
        return ChoiceChip(
          label: Text(opcao.value),
          selected: ativo,
          onSelected: (_) => onSelecionar(opcao.key),
          showCheckmark: false,
          backgroundColor: colors.surface,
          selectedColor: colors.primary,
          labelStyle: TextStyle(
            color: ativo ? Colors.white : colors.primary,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: colors.primary),
          shape: const StadiumBorder(),
        );
      }).toList(),
    );
  }
}
