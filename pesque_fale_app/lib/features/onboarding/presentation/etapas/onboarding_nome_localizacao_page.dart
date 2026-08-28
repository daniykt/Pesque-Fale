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

class OnboardingNomeLocalizacaoPage extends StatefulWidget {
  const OnboardingNomeLocalizacaoPage({super.key});

  @override
  State<OnboardingNomeLocalizacaoPage> createState() =>
      _OnboardingNomeLocalizacaoPageState();
}

class _OnboardingNomeLocalizacaoPageState
    extends State<OnboardingNomeLocalizacaoPage> {
  late final TextEditingController _nomeController;
  late final TextEditingController _localizacaoController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<OnboardingProvider>();
    _nomeController = TextEditingController(text: provider.nome);
    _localizacaoController = TextEditingController(text: provider.localizacao);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _localizacaoController.dispose();
    super.dispose();
  }

  InputDecoration _decoracao({
    required IconData icone,
    required String hint,
    required AppColors colors,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icone, color: colors.textSecondary),
      hintText: hint,
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdRadius,
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdRadius,
        borderSide: BorderSide(color: colors.border),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    return OnboardingLayoutBase(
      etapa: OnboardingEtapa.nomeLocalizacao,
      titulo: const Text('Qual é o seu nome e onde você pesca?'),
      subtitulo:
          'Essas informações ajudam a personalizar sua experiência e a '
          'conectar você com pescadores da sua região.',
      conteudo: Column(
        children: [
          TextField(
            controller: _nomeController,
            decoration: _decoracao(
              icone: Icons.person_outline,
              hint: 'Seu nome',
              colors: colors,
            ),
            onChanged: provider.onNomeChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _localizacaoController,
            decoration: _decoracao(
              icone: Icons.location_on_outlined,
              hint: 'Cidade, estado ou região',
              colors: colors,
            ),
            onChanged: provider.onLocalizacaoChanged,
          ),
        ],
      ),
      acoesInferior: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OnboardingBotaoPrincipal(
            label: 'Continuar',
            onPressed: provider.podeAvancarEtapaNomeLocalizacao
                ? provider.avancar
                : null,
          ),
          OnboardingLinkPular(onPressed: provider.pularEtapa),
        ],
      ),
    );
  }
}
