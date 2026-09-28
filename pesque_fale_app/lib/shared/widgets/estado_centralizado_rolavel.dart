import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Centraliza [child] na área disponível e passa a rolar quando ele não cabe.
///
/// Pensado para estados vazios, de erro e de início de busca: com o teclado
/// aberto ou com a fonte do sistema aumentada, a altura disponível pode ficar
/// menor que o conteúdo, e um `Center` simples estouraria (faixa amarela).
class EstadoCentralizadoRolavel extends StatelessWidget {
  const EstadoCentralizadoRolavel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) {
          return Center(child: Padding(padding: padding, child: child));
        }
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: Padding(padding: padding, child: child)),
          ),
        );
      },
    );
  }
}
