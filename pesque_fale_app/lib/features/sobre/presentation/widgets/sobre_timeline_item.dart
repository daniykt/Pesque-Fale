import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/sobre_conteudo.dart';

class SobreTimelineItem extends StatefulWidget {
  const SobreTimelineItem({
    super.key,
    required this.marco,
    required this.isLast,
  });

  final MarcoCronograma marco;
  final bool isLast;

  @override
  State<SobreTimelineItem> createState() => _SobreTimelineItemState();
}

class _SobreTimelineItemState extends State<SobreTimelineItem>
    with SingleTickerProviderStateMixin {
  static const double _pontoTamanho = 16;
  static const double _pontoBorda = 3;
  static const double _linhaLargura = 2;
  static const double _pulsoMin = 4;
  static const double _pulsoMax = 7;

  /// Só existe no marco atual; os demais pontos são estáticos.
  AnimationController? _pulso;

  bool get _atual => widget.marco.status == StatusMarco.atual;
  bool get _futuro => widget.marco.status == StatusMarco.futuro;

  @override
  void initState() {
    super.initState();
    if (_atual) {
      _pulso = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulso?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _pontoTamanho,
            child: Column(
              children: [
                _ponto(colors),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: _linhaLargura,
                      color: colors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _conteudo(context, colors)),
        ],
      ),
    );
  }

  Widget _ponto(AppColors colors) {
    final Color preenchimento;
    final Color borda;
    switch (widget.marco.status) {
      case StatusMarco.feito:
        preenchimento = colors.primaryAccent;
        borda = colors.primaryAccent;
      case StatusMarco.atual:
        preenchimento = colors.surface;
        borda = colors.primaryAccent;
      case StatusMarco.futuro:
        preenchimento = colors.background;
        borda = colors.border;
    }

    BoxDecoration decoracao(double? halo) => BoxDecoration(
      shape: BoxShape.circle,
      color: preenchimento,
      border: Border.all(color: borda, width: _pontoBorda),
      boxShadow: halo == null
          ? null
          : [
              BoxShadow(
                color: colors.primaryAccent.withValues(alpha: 0.15),
                spreadRadius: halo,
              ),
            ],
    );

    final pulso = _pulso;
    if (pulso == null) {
      return Container(
        width: _pontoTamanho,
        height: _pontoTamanho,
        decoration: decoracao(null),
      );
    }

    return AnimatedBuilder(
      animation: pulso,
      builder: (context, _) => Container(
        width: _pontoTamanho,
        height: _pontoTamanho,
        decoration: decoracao(
          _pulsoMin + (_pulsoMax - _pulsoMin) * pulso.value,
        ),
      ),
    );
  }

  Widget _conteudo(BuildContext context, AppColors colors) {
    final textTheme = Theme.of(context).textTheme;
    final marco = widget.marco;

    return Padding(
      padding: EdgeInsets.only(bottom: widget.isLast ? 0 : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            marco.data.toUpperCase(),
            style: textTheme.bodySmall?.copyWith(
              color: _futuro ? colors.textSecondary : colors.primaryAccent,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(marco.titulo, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            marco.descricao,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          if (_atual) ...[
            const SizedBox(height: AppSpacing.xs),
            _pill(textTheme, colors, 'Em andamento', colors.warning),
          ],
          if (marco.selo case final selo?) ...[
            const SizedBox(height: AppSpacing.xs),
            _pill(
              textTheme,
              colors,
              selo,
              colors.success,
              icone: Icons.check_circle_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(
    TextTheme textTheme,
    AppColors colors,
    String texto,
    Color cor, {
    IconData? icone,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.2),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 14, color: cor),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            texto,
            style: textTheme.labelSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
