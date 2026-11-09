import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/main_shell.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../pesquisa/domain/ponto.dart';
import '../../../pesquisa/providers/pesquisa_locais_provider.dart';
import '../../providers/ponto_detalhe_provider.dart';
import 'avaliar_bottom_sheet.dart';

class PontoAcoesRow extends StatelessWidget {
  const PontoAcoesRow({super.key, required this.ponto});

  final Ponto ponto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _avaliar(context),
              icon: const Icon(Icons.star_border),
              label: const Text('Avaliar'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _verNoMapa(context),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Ver no mapa'),
            ),
          ),
        ],
      ),
    );
  }

  void _avaliar(BuildContext context) {
    final logado = context.read<AuthProvider>().usuario != null;
    if (!logado) {
      AppSnackbar.showInfo(context, 'Faça login para avaliar');
      return;
    }

    final detalheProvider = context.read<PontoDetalheProvider>();
    AvaliarBottomSheet.show(
      context,
      ponto: ponto,
      existente: detalheProvider.minhaAvaliacao,
      onSaved: detalheProvider.aplicarNovaAvaliacao,
      onDeleted: detalheProvider.removerMinhaAvaliacao,
    );
  }

  void _verNoMapa(BuildContext context) {
    context.read<PesquisaLocaisProvider>().focarPonto(ponto);
    Navigator.of(context).popUntil(ModalRoute.withName('/home'));
    MainShell.shellKey.currentState?.selecionarAba(MainShell.pesquisaIndex);
  }
}
