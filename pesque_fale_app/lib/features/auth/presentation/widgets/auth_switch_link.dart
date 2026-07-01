import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onTap,
  });

  final String question;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final bodyMedium = Theme.of(context).textTheme.bodyMedium!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(question, style: bodyMedium.copyWith(color: colors.textSecondary)),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionLabel,
            style: bodyMedium.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
