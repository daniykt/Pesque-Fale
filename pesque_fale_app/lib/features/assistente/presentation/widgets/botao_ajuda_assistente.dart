import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'mascote_pira.dart';

class BotaoAjudaAssistente extends StatelessWidget {
  const BotaoAjudaAssistente({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return FloatingActionButton.extended(
      heroTag: 'botao-ajuda-assistente',
      tooltip: 'Abrir o ${MascotePira.nome}, assistente virtual',
      backgroundColor: colors.primary,
      foregroundColor: Colors.white,
      onPressed: () => Navigator.of(context).pushNamed('/assistente'),
      icon: const MascotePira(tamanho: 28, cor: Colors.white),
      label: const Text(
        'Ajuda',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}