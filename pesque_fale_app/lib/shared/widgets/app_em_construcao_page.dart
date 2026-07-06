import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Placeholder genérico para rotas cuja tela final ainda não foi
/// implementada em outra task.
class AppEmConstrucaoPage extends StatelessWidget {
  const AppEmConstrucaoPage({
    super.key,
    required this.titulo,
    this.mensagem = 'Estamos preparando esta tela.',
  });

  final String titulo;
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_outlined, size: 48),
              const SizedBox(height: AppSpacing.sm),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
