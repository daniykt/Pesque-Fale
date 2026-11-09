import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

class AuthHero extends StatelessWidget {
  const AuthHero({super.key, this.collapsed = false});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: collapsed ? 0 : 220,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.lg),
          bottomRight: Radius.circular(AppRadius.lg),
        ),
      ),
      child: collapsed
          ? null
          : Image.asset('assets/image/login/flat.png', fit: BoxFit.contain),
    );
  }
}
