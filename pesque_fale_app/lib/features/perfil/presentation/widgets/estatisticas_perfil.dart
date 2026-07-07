import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/usuario.dart';

class EstatisticasPerfil extends StatelessWidget {
  const EstatisticasPerfil({
    super.key,
    required this.usuario,
    required this.totalPublicacoes,
    this.onSeguidoresTap,
    this.onSeguindoTap,
  });

  final Usuario usuario;
  final int totalPublicacoes;
  final VoidCallback? onSeguidoresTap;
  final VoidCallback? onSeguindoTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Contador(valor: totalPublicacoes, label: 'Publicações'),
        _Contador(
          valor: usuario.seguidores,
          label: 'Seguidores',
          onTap: onSeguidoresTap,
        ),
        _Contador(
          valor: usuario.seguindo,
          label: 'Seguindo',
          onTap: onSeguindoTap,
        ),
      ],
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({
    required this.valor,
    required this.label,
    this.onTap,
  });

  final int valor;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final conteudo = Column(
      children: [
        Text(
          '$valor',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: colors.textSecondary),
        ),
      ],
    );

    if (onTap == null) return conteudo;

    return GestureDetector(
      onTap: onTap,
      child: conteudo,
    );
  }
}