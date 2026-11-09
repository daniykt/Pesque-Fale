import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Chip flutuante no topo da aba Seguindo quando chegam publicações novas
/// via realtime. O clique leva a lista pro topo e aplica as novas — nada é
/// injetado no meio do scroll do leitor sem ele pedir.
class NovasPublicacoesButton extends StatelessWidget {
  const NovasPublicacoesButton({
    super.key,
    required this.quantidade,
    required this.onTap,
  });

  final int quantidade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final texto = quantidade == 1
        ? '1 nova publicação'
        : '$quantidade novas publicações';

    return Material(
      color: colors.primaryAccent,
      elevation: 4,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_upward, color: colors.onPrimaryAccent, size: 18),
              const SizedBox(width: 6),
              Text(
                texto,
                style: TextStyle(
                  color: colors.onPrimaryAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
