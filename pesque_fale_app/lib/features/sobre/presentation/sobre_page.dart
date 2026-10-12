import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/sobre_conteudo.dart';
import 'widgets/sobre_hero.dart';
import 'widgets/sobre_stack.dart';
import 'widgets/sobre_time.dart';
import 'widgets/sobre_timeline.dart';

class SobrePage extends StatelessWidget {
  const SobrePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Sobre Nós')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SobreHero(),
              const SobreTimeline(marcos: marcosCronograma),
              const SobreTime(membros: membrosTime),
              const SobreStack(itens: stackItens),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: Text(
                    'Feito em Matão, SP · 2025–2026',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
