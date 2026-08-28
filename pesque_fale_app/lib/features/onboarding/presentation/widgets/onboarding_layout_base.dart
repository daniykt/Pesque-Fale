import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/onboarding_etapa.dart';
import 'onboarding_barra_progresso.dart';
import 'onboarding_fab_tema.dart';

class OnboardingLayoutBase extends StatelessWidget {
  const OnboardingLayoutBase({
    super.key,
    required this.etapa,
    required this.titulo,
    required this.subtitulo,
    required this.conteudo,
    required this.acoesInferior,
  });

  final OnboardingEtapa etapa;

  /// Widget do título (permite destacar trechos, ex.: o nome do usuário).
  final Widget titulo;
  final String subtitulo;
  final Widget conteudo;
  final Widget acoesInferior;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OnboardingBarraProgresso(etapaAtual: etapa),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        DefaultTextStyle.merge(
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          child: titulo,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          subtitulo,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        conteudo,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  child: acoesInferior,
                ),
              ],
            ),
            const Positioned(
              bottom: AppSpacing.lg,
              right: AppSpacing.lg,
              child: OnboardingFabTema(),
            ),
          ],
        ),
      ),
    );
  }
}
