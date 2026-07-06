import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/usuario.dart';

class EstatisticasPerfil extends StatelessWidget {
  const EstatisticasPerfil({
    super.key,
    required this.usuario,
    required this.totalPublicacoes,
  });

  final Usuario usuario;
  final int totalPublicacoes;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Contador(valor: totalPublicacoes, label: 'Publicações'),
        // Contadores de seguidores/seguindo não são tocáveis: falta o
        // endpoint paginado de listagem no backend (gap de contrato — ver
        // issue de continuação da Fase 2).
        _Contador(valor: usuario.seguidores, label: 'Seguidores'),
        _Contador(valor: usuario.seguindo, label: 'Seguindo'),
      ],
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({required this.valor, required this.label});

  final int valor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      children: [
        Text(
          '$valor',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}
