import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class MapaSkeleton extends StatelessWidget {
  const MapaSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(color: colors.surfaceVariant),
        CircularProgressIndicator(color: colors.primary, strokeWidth: 2.5),
      ],
    );
  }
}
