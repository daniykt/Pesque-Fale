import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../domain/onboarding_etapa.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_botao_principal.dart';
import '../widgets/onboarding_layout_base.dart';
import '../widgets/onboarding_link_pular.dart';
import '../widgets/onboarding_moldura_tracejada.dart';

class OnboardingFotoCapaPage extends StatelessWidget {
  const OnboardingFotoCapaPage({super.key});

  Future<void> _escolherCapa(
    BuildContext context,
    OnboardingProvider provider,
  ) async {
    final ok = await provider.escolherEEnviarCapa();
    if (!context.mounted || ok) return;
    if (provider.errorMessage != null) {
      AppSnackbar.showError(context, provider.errorMessage!);
    }
  }

  Future<void> _concluirEIrParaSucesso(
    BuildContext context,
    OnboardingProvider provider,
    String userId,
  ) async {
    final ok = await provider.concluir(userId: userId);
    if (!context.mounted || ok) return;
    AppSnackbar.showError(
      context,
      provider.errorMessage ?? 'Não foi possível salvar o perfil.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    final temCapa = provider.fotoCapaUrl != null;
    final userId = context.watch<AuthProvider>().usuario!.id;
    final acoesDesabilitadas = provider.concluindo;

    return OnboardingLayoutBase(
      etapa: OnboardingEtapa.fotoCapa,
      titulo: const Text('Adicione uma foto de capa'),
      subtitulo:
          'Dê um toque pessoal ao seu perfil com uma imagem de fundo.',
      conteudo: GestureDetector(
        onTap: provider.uploadingCapa
            ? null
            : () => _escolherCapa(context, provider),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (temCapa)
                ClipRRect(
                  borderRadius: AppRadius.mdRadius,
                  child: Image.network(
                    provider.fotoCapaUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              else
                OnboardingMolduraTracejada(
                  corBorda: colors.border,
                  borderRadius: AppRadius.md,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Clique para adicionar uma capa',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              if (provider.uploadingCapa)
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.mdRadius,
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              if (temCapa)
                Positioned(
                  bottom: 8,
                  right: 8,
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
      acoesInferior: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OnboardingBotaoPrincipal(
            label: temCapa ? 'Continuar' : 'Continuar sem capa',
            loading: provider.concluindo,
            onPressed: acoesDesabilitadas
                ? null
                : () => _concluirEIrParaSucesso(context, provider, userId),
          ),
          OnboardingLinkPular(
            onPressed: acoesDesabilitadas
                ? null
                : () => _concluirEIrParaSucesso(context, provider, userId),
          ),
        ],
      ),
    );
  }
}
