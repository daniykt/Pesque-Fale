import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class DropdownFiltro<T> extends StatelessWidget {
  const DropdownFiltro({
    super.key,
    required this.titulo,
    required this.valor,
    required this.itens,
    required this.labelDe,
    required this.onChanged,
  });

  final String titulo;
  final T valor;
  final List<T> itens;
  final String Function(T) labelDe;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colors.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: AppRadius.smRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<T>(
              initialValue: valor,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: colors.textSecondary),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              items: itens
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(labelDe(item)),
                    ),
                  )
                  .toList(),
              onChanged: (novo) {
                if (novo != null) onChanged(novo);
              },
            ),
          ),
        ),
      ],
    );
  }
}
