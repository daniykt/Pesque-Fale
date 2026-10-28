import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class AppSnackbar {
  AppSnackbar._();

  static void showError(BuildContext context, String message) {
    final colors = Theme.of(context).extension<AppColors>()!;
    _mostrar(
      context,
      message,
      fundo: colors.danger,
      texto: colors.onDanger,
      duracao: const Duration(seconds: 4),
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final colors = Theme.of(context).extension<AppColors>()!;
    _mostrar(
      context,
      message,
      fundo: colors.success,
      texto: colors.onSuccess,
      duracao: duration,
    );
  }

  /// [acaoLabel] e [onAcao] juntos adicionam um botão de ação (ex: "Abrir"
  /// configurações) ao lado do X.
  static void showWarning(
    BuildContext context,
    String message, {
    String? acaoLabel,
    VoidCallback? onAcao,
  }) {
    final colors = Theme.of(context).extension<AppColors>()!;
    _mostrar(
      context,
      message,
      fundo: colors.warning,
      texto: colors.onWarning,
      duracao: const Duration(seconds: 4),
      acao: acaoLabel != null && onAcao != null
          ? SnackBarAction(
              label: acaoLabel,
              textColor: colors.onWarning,
              onPressed: onAcao,
            )
          : null,
    );
  }

  static void showInfo(BuildContext context, String message) {
    final colors = Theme.of(context).extension<AppColors>()!;
    _mostrar(
      context,
      message,
      fundo: colors.primary,
      texto: Colors.white,
      duracao: const Duration(seconds: 3),
    );
  }

  static void _mostrar(
    BuildContext context,
    String message, {
    required Color fundo,
    required Color texto,
    required Duration duracao,
    SnackBarAction? acao,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: texto)),
          backgroundColor: fundo,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
          duration: duracao,
          action: acao,
          persist: false,
          showCloseIcon: true,
          closeIconColor: texto,
        ),
      );
  }
}