import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import 'tipo_badge.dart';

enum BadgeTamanho {
  /// Comentários.
  sm,

  /// Perfil, publicações e busca.
  md;

  double get fontSize => this == BadgeTamanho.sm ? 9 : 10;
}

/// Pílula "DEV" (outline) ou "OFICIAL" (sólida) com tooltip no long press.
class BadgeEquipe extends StatelessWidget {
  const BadgeEquipe({
    super.key,
    required this.tipo,
    this.tamanho = BadgeTamanho.md,
  });

  final TipoBadge tipo;
  final BadgeTamanho tamanho;

  static String mensagemDe(TipoBadge tipo) => switch (tipo) {
    TipoBadge.dev => 'Desenvolvedor do Pesque & Fale',
    TipoBadge.oficial => 'Conta oficial do Pesque & Fale',
  };

  static String rotuloDe(TipoBadge tipo) => switch (tipo) {
    TipoBadge.dev => 'DEV',
    TipoBadge.oficial => 'OFICIAL',
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final escuro = Theme.of(context).brightness == Brightness.dark;

    final Color fundo;
    final Color borda;
    final Color texto;
    switch (tipo) {
      case TipoBadge.dev:
        fundo = colors.primaryAccent.withValues(alpha: 0.14);
        borda = colors.primaryAccent.withValues(alpha: 0.30);
        texto = colors.primaryAccent;
      case TipoBadge.oficial:
        // No escuro o primary some contra o background; inverte pro accent.
        fundo = escuro ? colors.primaryAccent : colors.primary;
        borda = fundo;
        texto = escuro ? colors.onPrimaryAccent : Colors.white;
    }

    return Tooltip(
      message: mensagemDe(tipo),
      triggerMode: TooltipTriggerMode.longPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: fundo,
          // Borda também no sólido pra os dois chips terem a mesma altura.
          border: Border.all(color: borda),
          borderRadius: AppRadius.pillRadius,
        ),
        child: Text(
          rotuloDe(tipo),
          style: TextStyle(
            color: texto,
            fontSize: tamanho.fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
