import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../tour/providers/tour_provider.dart';
import '../../domain/onboarding_etapa.dart';
import '../widgets/onboarding_botao_principal.dart';
import '../widgets/onboarding_layout_base.dart';

class OnboardingSucessoPage extends StatelessWidget {
  const OnboardingSucessoPage({super.key});

  Future<void> _irParaHome(BuildContext context) async {
    final userId = context.read<AuthProvider>().usuario?.id;
    if (userId != null) {
      await context.read<TourProvider>().iniciarSePendente(userId);
    }
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return OnboardingLayoutBase(
      etapa: OnboardingEtapa.sucesso,
      titulo: const Text('Perfil completo, bora pescar!'),
      subtitulo:
          'Seu perfil foi configurado com sucesso. Agora você pode explorar '
          'locais de pesca, conectar-se com outros pescadores e '
          'compartilhar suas aventuras.',
      conteudo: Center(
        child: Container(
          width: 100,
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primary.withValues(alpha: 0.1),
          ),
          child: const Text('🎉', style: TextStyle(fontSize: 48)),
        ),
      ),
      acoesInferior: OnboardingBotaoPrincipal(
        label: 'Ir para Home',
        icone: Icons.home_outlined,
        onPressed: () => _irParaHome(context),
      ),
    );
  }
}
