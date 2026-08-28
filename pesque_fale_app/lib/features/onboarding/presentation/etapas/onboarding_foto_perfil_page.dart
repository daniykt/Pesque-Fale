import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../domain/onboarding_etapa.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_botao_principal.dart';
import '../widgets/onboarding_layout_base.dart';
import '../widgets/onboarding_link_pular.dart';
import '../widgets/onboarding_moldura_tracejada.dart';

class OnboardingFotoPerfilPage extends StatelessWidget {
  const OnboardingFotoPerfilPage({super.key});

  static const _tamanho = 160.0;

  Future<void> _escolherFoto(
    BuildContext context,
    OnboardingProvider provider,
  ) async {
    final ok = await provider.escolherEEnviarFoto();
    if (!context.mounted || ok) return;
    if (provider.errorMessage != null) {
      AppSnackbar.showError(context, provider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    final temFoto = provider.fotoPerfilUrl != null;

    return OnboardingLayoutBase(
      etapa: OnboardingEtapa.fotoPerfil,
      titulo: const Text('Adicione sua foto de perfil'),
      subtitulo:
          'Uma boa foto ajuda outros pescadores a te reconhecerem na '
          'comunidade.',
      conteudo: Center(
        child: GestureDetector(
          onTap: provider.uploadingFoto
              ? null
              : () => _escolherFoto(context, provider),
          child: SizedBox(
            width: _tamanho,
            height: _tamanho,
            child: Stack(
              children: [
                if (temFoto)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(_tamanho / 2),
                    child: Image.network(
                      provider.fotoPerfilUrl!,
                      width: _tamanho,
                      height: _tamanho,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  OnboardingMolduraTracejada(
                    corBorda: colors.border,
                    borderRadius: _tamanho / 2,
                    child: SizedBox(
                      width: _tamanho,
                      height: _tamanho,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 32,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Clique para adicionar',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (provider.uploadingFoto)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
                if (temFoto)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      acoesInferior: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OnboardingBotaoPrincipal(
            label: temFoto ? 'Continuar' : 'Continuar sem foto',
            onPressed: provider.avancar,
          ),
          OnboardingLinkPular(onPressed: provider.pularEtapa),
        ],
      ),
    );
  }
}
