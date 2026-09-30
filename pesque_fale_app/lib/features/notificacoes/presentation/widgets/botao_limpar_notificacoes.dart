import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../providers/badge_notificacoes_provider.dart';
import '../../providers/notificacoes_provider.dart';

class BotaoLimparNotificacoes extends StatelessWidget {
  const BotaoLimparNotificacoes({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificacoesProvider>();
    final visivel =
        provider.status == StatusNotificacoes.carregado && provider.temAlguma;
    if (!visivel) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.delete_sweep_outlined),
      tooltip: 'Limpar todas',
      onPressed: () => _limparTodas(context),
    );
  }

  Future<void> _limparTodas(BuildContext context) async {
    final colors = Theme.of(context).extension<AppColors>()!;
    final provider = context.read<NotificacoesProvider>();
    final badge = context.read<BadgeNotificacoesProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Limpar notificações'),
        content: const Text(
          'Todas as suas notificações serão apagadas. Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Limpar', style: TextStyle(color: colors.danger)),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    messenger.hideCurrentSnackBar();
    final limpou = await provider.limparTodas();
    if (limpou) {
      badge.atualizar();
    } else if (context.mounted) {
      AppSnackbar.showError(context, 'Não foi possível limpar as notificações.');
    }
  }
}