import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class ConfirmacaoSheet {
  ConfirmacaoSheet._();

  static Future<bool> show(
    BuildContext context, {
    required String titulo,
    required String mensagem,
    required String confirmar,
    required IconData iconeConfirmar,
    required String cancelar,
  }) async {
    final confirmou = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).extension<AppColors>()!;
        final textos = Theme.of(sheetContext).textTheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Text(
                  titulo,
                  style: textos.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Text(
                  mensagem,
                  style: textos.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(iconeConfirmar, color: colors.danger),
                title: Text(confirmar, style: TextStyle(color: colors.danger)),
                onTap: () => Navigator.pop(sheetContext, true),
              ),
              ListTile(
                leading: Icon(Icons.arrow_back, color: colors.textPrimary),
                title: Text(cancelar),
                onTap: () => Navigator.pop(sheetContext, false),
              ),
            ],
          ),
        );
      },
    );
    return confirmou ?? false;
  }
}
