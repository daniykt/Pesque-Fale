import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size.fromHeight(48)),
          side: WidgetStateProperty.all(
            BorderSide(color: colors.primary, width: 1.5),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return colors.primary;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return Colors.white;
            return colors.primary;
          }),
          overlayColor: WidgetStateProperty.all(
            colors.primary.withValues(alpha: 0.08),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        child: loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Carregando...'),
                ],
              )
            : Text(label.toUpperCase()),
      ),
    );
  }
}
