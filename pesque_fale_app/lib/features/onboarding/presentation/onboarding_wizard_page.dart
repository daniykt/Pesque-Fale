import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/onboarding_etapa.dart';
import '../providers/onboarding_provider.dart';
import 'etapas/onboarding_bio_page.dart';
import 'etapas/onboarding_boas_vindas_page.dart';
import 'etapas/onboarding_foto_capa_page.dart';
import 'etapas/onboarding_foto_perfil_page.dart';
import 'etapas/onboarding_nome_localizacao_page.dart';
import 'etapas/onboarding_sucesso_page.dart';
import 'etapas/onboarding_username_page.dart';

class OnboardingWizardPage extends StatelessWidget {
  const OnboardingWizardPage({super.key});

  Widget _paginaParaEtapa(OnboardingEtapa etapa) {
    switch (etapa) {
      case OnboardingEtapa.boasVindas:
        return const OnboardingBoasVindasPage();
      case OnboardingEtapa.fotoPerfil:
        return const OnboardingFotoPerfilPage();
      case OnboardingEtapa.nomeLocalizacao:
        return const OnboardingNomeLocalizacaoPage();
      case OnboardingEtapa.username:
        return const OnboardingUsernamePage();
      case OnboardingEtapa.bio:
        return const OnboardingBioPage();
      case OnboardingEtapa.fotoCapa:
        return const OnboardingFotoCapaPage();
      case OnboardingEtapa.sucesso:
        return const OnboardingSucessoPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final permitePop =
        provider.etapaAtual == OnboardingEtapa.boasVindas ||
        provider.etapaAtual == OnboardingEtapa.sucesso;

    return PopScope(
      canPop: permitePop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        provider.voltar();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey(provider.etapaAtual),
          child: _paginaParaEtapa(provider.etapaAtual),
        ),
      ),
    );
  }
}
