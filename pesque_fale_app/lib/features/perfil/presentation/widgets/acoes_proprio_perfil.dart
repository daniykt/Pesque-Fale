import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// CTAs do próprio perfil: "Editar perfil" (ação primária, ~2/3) e "Ajustes"
/// (secundária, ~1/3).
///
/// O layout é adaptativo porque o público usa fonte ampliada: um
/// `Expanded(flex: 1)` fixo estouraria o rótulo de "Ajustes". Quando os dois
/// não cabem lado a lado, eles são empilhados em vez de truncados.
class AcoesProprioPerfil extends StatelessWidget {
  const AcoesProprioPerfil({
    super.key,
    required this.onEditar,
    required this.onAjustes,
  });

  final VoidCallback onEditar;
  final VoidCallback onAjustes;

  static const _rotuloEditar = 'Editar perfil';
  static const _rotuloAjustes = 'Ajustes';
  static const _iconeTamanho = 18.0;
  static const _iconeGap = 8.0;
  static const _folga = 8.0;
  static const _padding = EdgeInsets.symmetric(horizontal: AppSpacing.md);

  double _larguraNecessaria(BuildContext context, String rotulo) {
    final painter = TextPainter(
      text: TextSpan(
        text: rotulo,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final largura =
        _padding.horizontal +
        _iconeTamanho +
        _iconeGap +
        painter.width +
        _folga;
    painter.dispose();
    return largura;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final forma = RoundedRectangleBorder(borderRadius: AppRadius.mdRadius);

    final editar = FilledButton.icon(
      onPressed: onEditar,
      icon: const Icon(Icons.edit_outlined),
      label: const Text(_rotuloEditar),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, kMinInteractiveDimension),
        padding: _padding,
        iconSize: _iconeTamanho,
        shape: forma,
      ),
    );

    final ajustes = OutlinedButton.icon(
      onPressed: onAjustes,
      icon: const Icon(Icons.settings_outlined),
      label: const Text(_rotuloAjustes),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, kMinInteractiveDimension),
        padding: _padding,
        iconSize: _iconeTamanho,
        shape: forma,
        foregroundColor: colors.primaryAccent,
        side: BorderSide(color: colors.primaryAccent, width: 1.5),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final larguraEditar = _larguraNecessaria(context, _rotuloEditar);
        final larguraAjustes = _larguraNecessaria(context, _rotuloAjustes);
        final terco = (constraints.maxWidth - AppSpacing.sm) / 3;

        final cabeLadoALado =
            larguraEditar + AppSpacing.sm + math.max(larguraAjustes, terco) <=
            constraints.maxWidth;

        if (cabeLadoALado) {
          return Row(
            children: [
              Expanded(child: editar),
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: terco),
                child: ajustes,
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            editar,
            const SizedBox(height: AppSpacing.sm),
            ajustes,
          ],
        );
      },
    );
  }
}
