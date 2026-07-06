import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/app_snackbar.dart';
import '../../../providers/editar_perfil_provider.dart';

/// Idle mostra "Salvar Alterações", salvando mostra spinner e salvo mostra
/// check verde — some enquanto nenhuma alteração nova for feita depois.
class BotaoSalvar extends StatelessWidget {
  const BotaoSalvar({super.key});

  Future<void> _salvar(
    BuildContext context,
    EditarPerfilProvider provider,
  ) async {
    final ok = await provider.salvar();
    if (!context.mounted) return;

    if (ok) {
      AppSnackbar.showSuccess(context, 'Perfil atualizado com sucesso!');
    } else {
      AppSnackbar.showError(
        context,
        provider.errorMessage ?? 'Não foi possível salvar as alterações.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditarPerfilProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    final salvando = provider.status == SalvamentoStatus.salvando;
    final salvo =
        provider.status == SalvamentoStatus.salvo && !provider.temAlteracoes;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: (!provider.podeSalvar || salvando)
            ? null
            : () => _salvar(context, provider),
        style: salvo
            ? FilledButton.styleFrom(backgroundColor: colors.success)
            : null,
        child: salvando
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : salvo
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Salvo!'),
                ],
              )
            : const Text('Salvar Alterações'),
      ),
    );
  }
}
