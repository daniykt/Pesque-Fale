import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/onboarding_etapa.dart';
import '../../domain/username_onboarding_state.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_botao_principal.dart';
import '../widgets/onboarding_layout_base.dart';

class OnboardingUsernamePage extends StatefulWidget {
  const OnboardingUsernamePage({super.key});

  @override
  State<OnboardingUsernamePage> createState() =>
      _OnboardingUsernamePageState();
}

class _OnboardingUsernamePageState extends State<OnboardingUsernamePage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<OnboardingProvider>().username,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _statusWidget(
    UsernameOnboardingState estado,
    AppColors colors,
    TextTheme textTheme,
  ) {
    switch (estado) {
      case UsernameOnboardingState.idle:
        return const SizedBox.shrink();
      case UsernameOnboardingState.validating:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Verificando...',
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        );
      case UsernameOnboardingState.invalidoFormato:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: colors.danger, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                '3-20 caracteres. Use letras, números, _ ou .',
                style: textTheme.bodySmall?.copyWith(color: colors.danger),
              ),
            ),
          ],
        );
      case UsernameOnboardingState.indisponivel:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, color: colors.danger, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Já em uso',
              style: textTheme.bodySmall?.copyWith(color: colors.danger),
            ),
          ],
        );
      case UsernameOnboardingState.disponivel:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: colors.success.withValues(alpha: 0.15),
            borderRadius: AppRadius.pillRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: colors.success, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '✅ Disponível',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return OnboardingLayoutBase(
      etapa: OnboardingEtapa.username,
      titulo: const Text('Escolha seu username único'),
      subtitulo:
          'Será usado no link do seu perfil e para te marcarem em posts '
          'e comentários.',
      conteudo: Column(
        children: [
          Text(
            'Ex: joao_pescador, maria.2024',
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.alternate_email, color: colors.primary),
              hintText: 'seu_username',
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
            ),
            onChanged: provider.onUsernameChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          _statusWidget(provider.usernameOnboardingState, colors, textTheme),
        ],
      ),
      acoesInferior: OnboardingBotaoPrincipal(
        label: 'Continuar',
        onPressed: provider.podeAvancarEtapaUsername
            ? provider.avancar
            : null,
      ),
    );
  }
}
