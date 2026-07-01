import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/image/login/logo1.png', height: 48),
              const SizedBox(width: 12),
              Image.asset('assets/image/login/logo2.png', height: 40),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.antonSc(
              fontSize: 28,
              letterSpacing: 2,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
