import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';

/// Substitui o AppDrawer quando o usuário está vendo o próprio perfil.
class PerfilOpcoesSheet extends StatelessWidget {
  const PerfilOpcoesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => const PerfilOpcoesSheet(),
    );
  }

  Future<void> _sair(BuildContext context) async {
    Navigator.pop(context);
    await context.read<AuthProvider>().signOut();
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/cadastro', (route) => false);
    }
  }

  void _reiniciarTour(BuildContext context) {
    Navigator.pop(context);
    AppSnackbar.showError(context, 'Tour de onboarding ainda não implementado.');
  }

  void _sobreNos(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/sobre');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('Sobre Nós'),
            onTap: () => _sobreNos(context),
          ),
          SwitchListTile(
            secondary: Icon(
              themeProvider.isDarkMode
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            title: Text(
              themeProvider.isDarkMode ? 'Modo Escuro' : 'Modo Claro',
            ),
            value: themeProvider.isDarkMode,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Reiniciar Tour'),
            onTap: () => _reiniciarTour(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout, color: colors.danger),
            title: Text('Sair', style: TextStyle(color: colors.danger)),
            onTap: () => _sair(context),
          ),
        ],
      ),
    );
  }
}
