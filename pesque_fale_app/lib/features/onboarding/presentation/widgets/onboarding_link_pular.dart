import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class OnboardingLinkPular extends StatelessWidget {
  const OnboardingLinkPular({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          'Pular esta etapa',
          style: TextStyle(
            color: colors.textSecondary,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
