import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../data/sobre_conteudo.dart';
import 'sobre_timeline_item.dart';
import 'sobre_titulo_secao.dart';

class SobreTimeline extends StatelessWidget {
  const SobreTimeline({super.key, required this.marcos});

  final List<MarcoCronograma> marcos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SobreTituloSecao('Nossa trajetória'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              for (var i = 0; i < marcos.length; i++)
                SobreTimelineItem(
                  marco: marcos[i],
                  isLast: i == marcos.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
