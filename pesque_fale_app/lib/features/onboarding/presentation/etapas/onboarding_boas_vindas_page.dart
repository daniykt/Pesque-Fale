import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/onboarding_etapa.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_botao_principal.dart';
import '../widgets/onboarding_layout_base.dart';

class OnboardingBoasVindasPage extends StatelessWidget {
  const OnboardingBoasVindasPage({super.key});

  static const _itens = [
    (Icons.photo_camera_outlined, 'Foto de perfil'),
    (Icons.person_outline, 'Nome e localização'),
    (Icons.alternate_email, 'Username único'),
    (Icons.edit_note_outlined, 'Bio'),
    (Icons.image_outlined, 'Foto de capa'),
  ];

  Widget _titulo(String nome, AppColors colors) {
    final nomeTrim = nome.trim();
    if (nomeTrim.isEmpty) {
      return const Text('Bem-vindo ao Pesque & Fale!');
    }
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Bem-vindo ao Pesque & Fale, '),
          TextSpan(
            text: nomeTrim,
            style: TextStyle(color: colors.primaryAccent),
          ),
          const TextSpan(text: '!'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    return OnboardingLayoutBase(
      etapa: OnboardingEtapa.boasVindas,
      titulo: _titulo(provider.nome, colors),
      subtitulo:
          'Vamos montar o seu perfil para que outros pescadores possam '
          'te conhecer. Vai levar menos de 2 minutos!',
      conteudo: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: AppRadius.mdRadius,
        ),
        child: Column(
          children: [
            for (var i = 0; i < _itens.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(_itens[i].$1, color: colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(_itens[i].$2)),
                ],
              ),
            ],
          ],
        ),
      ),
      acoesInferior: OnboardingBotaoPrincipal(
        label: 'Vamos começar!',
        onPressed: provider.avancar,
      ),
    );
  }
}
