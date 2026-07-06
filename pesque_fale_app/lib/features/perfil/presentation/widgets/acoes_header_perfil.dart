import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';

/// Ícones de ação sobrepostos ao banner (editar + menu), exibidos apenas
/// quando o usuário está vendo o próprio perfil.
class AcoesHeaderPerfil extends StatelessWidget {
  const AcoesHeaderPerfil({
    super.key,
    required this.onEditar,
    required this.onMenu,
  });

  final VoidCallback onEditar;
  final VoidCallback onMenu;

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
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              tooltip: 'Mais opções',
              onPressed: onMenu,
            ),
          ],
        ),
      ),
    );
  }
}
