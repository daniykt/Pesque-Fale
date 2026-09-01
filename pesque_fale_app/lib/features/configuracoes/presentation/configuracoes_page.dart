import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tour/providers/tour_provider.dart';
import '../providers/preferencias_provider.dart';
import 'widgets/configuracoes_secao.dart';

class ConfiguracoesPage extends StatelessWidget {
  const ConfiguracoesPage({super.key});

  void _verTutorial(BuildContext context) {
    final tourProvider = context.read<TourProvider>();
    Navigator.of(context).popUntil(ModalRoute.withName('/home'));
    tourProvider.iniciarManual();
  }

  Future<void> _confirmarSaida(BuildContext context) async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Sair', style: TextStyle(color: colors.danger)),
          ),
        ],
      ),
    );

    if (confirmou != true) return;
    if (!context.mounted) return;

    await context.read<AuthProvider>().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/cadastro', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final preferenciasProvider = context.watch<PreferenciasProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          ConfiguracoesSecao(
            titulo: 'Aparência',
            itens: [
              SwitchListTile(
                secondary: Icon(
                  themeProvider.isDarkMode
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                ),
                title: const Text('Modo escuro'),
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
            ],
          ),
          ConfiguracoesSecao(
            titulo: 'Notificações',
            itens: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Receber notificações'),
                subtitle: const Text(
                  'Curtidas, comentários, novos seguidores e mensagens.',
                ),
                value: preferenciasProvider.notificacoesAtivas,
                onChanged: preferenciasProvider.setNotificacoesAtivas,
              ),
            ],
          ),
          ConfiguracoesSecao(
            titulo: 'Conta',
            itens: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Editar perfil'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/perfil/editar'),
              ),
              ListTile(
                leading: const Icon(Icons.school_outlined),
                title: const Text('Ver tutorial novamente'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _verTutorial(context),
              ),
              ListTile(
                leading: Icon(Icons.logout, color: colors.danger),
                title: Text(
                  'Sair da conta',
                  style: TextStyle(color: colors.danger),
                ),
                onTap: () => _confirmarSaida(context),
              ),
            ],
          ),
          ConfiguracoesSecao(
            titulo: 'Sobre',
            itens: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Sobre o app'),
                onTap: () => Navigator.pushNamed(context, '/sobre'),
              ),
              ListTile(
                leading: const Icon(Icons.tag),
                title: const Text('Versão'),
                trailing: Text(
                  AppInfo.version,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
