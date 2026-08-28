import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';

class OnboardingFabTema extends StatelessWidget {
  const OnboardingFabTema({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Material(
      color: colors.surface,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.read<ThemeProvider>().toggleTheme(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
