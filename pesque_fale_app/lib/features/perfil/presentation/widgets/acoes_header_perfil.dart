import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';

/// Ícones de ação sobrepostos ao banner, exibidos apenas quando o usuário
/// está vendo o próprio perfil: editar perfil, abrir Configurações e abrir
/// Sobre Nós — cada atalho direto, sem passar por sheet intermediário.
class AcoesHeaderPerfil extends StatelessWidget {
  const AcoesHeaderPerfil({
    super.key,
    required this.onEditar,
    required this.onConfiguracoes,
    required this.onSobre,
  });

  final VoidCallback onEditar;
  final VoidCallback onConfiguracoes;
  final VoidCallback onSobre;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: AppRadius.mdRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: 'Editar perfil',
              onPressed: onEditar,
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              tooltip: 'Configurações',
              onPressed: onConfiguracoes,
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              tooltip: 'Sobre Nós',
              onPressed: onSobre,
            ),
          ],
        ),
      ),
    );
  }
}
