import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'auth_logo.dart';

class AuthLogoTitle extends StatelessWidget {
  const AuthLogoTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          const AuthLogo(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.antonSc(
              fontSize: 28,
              letterSpacing: 2,
              color: colors.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }
}