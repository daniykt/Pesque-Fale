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
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, kMinInteractiveDimension),
          ),
          child: Text(
            actionLabel,
            style: bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
