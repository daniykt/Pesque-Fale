import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/onboarding_etapa.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_botao_principal.dart';
import '../widgets/onboarding_layout_base.dart';
import '../widgets/onboarding_link_pular.dart';

class OnboardingBioPage extends StatefulWidget {
  const OnboardingBioPage({super.key});

  static const _limiteCaracteres = 300;

  @override
  State<OnboardingBioPage> createState() => _OnboardingBioPageState();
}

class _OnboardingBioPageState extends State<OnboardingBioPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<OnboardingProvider>().bio,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final tamanho = provider.bio.length;
    final noLimite = tamanho >= OnboardingBioPage._limiteCaracteres;

    return OnboardingLayoutBase(
      etapa: OnboardingEtapa.bio,
      titulo: const Text('Conte um pouco sobre você'),
      subtitulo:
          'Uma boa bio ajuda outros pescadores a te conhecerem e a se '
          'conectarem com você.',
      conteudo: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: AppRadius.mdRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              minLines: 4,
              maxLength: OnboardingBioPage._limiteCaracteres,
              decoration: const InputDecoration(
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 64),
                  child: Icon(Icons.edit_note_outlined),
                ),
                hintText:
                    'Sou pescador há 10 anos, adoro pescar em rios de '
                    'água doce...',
                counterText: '',
                border: InputBorder.none,
              ),
              onChanged: provider.onBioChanged,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$tamanho/${OnboardingBioPage._limiteCaracteres}',
                style: textTheme.bodySmall?.copyWith(
                  color: noLimite ? colors.danger : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
      acoesInferior: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OnboardingBotaoPrincipal(
            label: 'Continuar',
            onPressed: provider.avancar,
          ),
          OnboardingLinkPular(onPressed: provider.pularEtapa),
        ],
      ),
    );
  }
}
