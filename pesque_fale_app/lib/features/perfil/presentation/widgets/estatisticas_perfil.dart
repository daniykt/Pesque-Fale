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
      children: [
        Expanded(
          child: _Contador(valor: totalPublicacoes, label: 'Publicações'),
        ),
        Expanded(
          child: _Contador(
            valor: usuario.seguidores,
            label: 'Seguidores',
            onTap: onSeguidoresTap,
          ),
        ),
        Expanded(
          child: _Contador(
            valor: usuario.seguindo,
            label: 'Seguindo',
            onTap: onSeguindoTap,
          ),
        ),
      ],
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({required this.valor, required this.label, this.onTap});

  final int valor;
  final String label;
  final VoidCallback? onTap;

  static const double _raio = 12;
  static const EdgeInsets _padding = EdgeInsets.symmetric(vertical: 8);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final conteudo = Padding(
      padding: _padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
      ),
    );

    if (onTap == null) return conteudo;

    // InkWell precisa de um Material ancestral para pintar o ripple. O
    // Scaffold já provê um, mas garantimos aqui para funcionar em qualquer
    // contexto (ex.: dentro de um Dialog).
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_raio),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_raio),
        child: conteudo,
      ),
    );
  }
}