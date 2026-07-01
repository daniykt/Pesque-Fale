import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class AppSnackbar {
  AppSnackbar._();

  static void showError(BuildContext context, String message) {
    final colors = Theme.of(context).extension<AppColors>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'X',
          textColor: Colors.white,
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    final colors = Theme.of(context).extension<AppColors>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'X',
          textColor: Colors.white,
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}
