import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/cloudinary_url.dart';
import '../../domain/notificacao.dart';

class AvatarComTipo extends StatelessWidget {
  const AvatarComTipo({
    super.key,
    required this.nome,
    required this.foto,
    required this.tipo,
  });

  final String? nome;
  final String? foto;
  final TipoNotificacao tipo;

  static const double _raioAvatar = 24;
  static const double _tamanhoBadge = 20;

  static const List<Color> _coresIniciais = [
    Color(0xFF0EA5E9),
    Color(0xFF22C55E),
    Color(0xFFF97316),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFEAB308),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final fotoOtimizada = CloudinaryUrl.avatar(foto, tamanho: 96);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: _raioAvatar,
          backgroundColor: _corIniciais(nome),
          backgroundImage: fotoOtimizada != null
              ? NetworkImage(fotoOtimizada)
              : null,
          child: fotoOtimizada == null
              ? Text(
                  _iniciais(nome),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            width: _tamanhoBadge,
            height: _tamanhoBadge,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _corDoTipo(tipo, colors),
              border: Border.all(color: colors.surface, width: 2),
            ),
            child: Icon(_iconeDoTipo(tipo), size: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }

  String _iniciais(String? nome) {
    final n = nome?.trim();
    if (n == null || n.isEmpty) return '?';
    final partes = n.split(RegExp(r'\s+'));
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1))
        .toUpperCase();
  }

  Color _corIniciais(String? nome) {
    final n = nome ?? '';
    final indice = n.isEmpty ? 0 : n.codeUnits.reduce((a, b) => a + b);
    return _coresIniciais[indice % _coresIniciais.length];
  }

  IconData _iconeDoTipo(TipoNotificacao tipo) {
    switch (tipo) {
      case TipoNotificacao.seguindo:
        return Icons.person_add;
      case TipoNotificacao.curtida:
        return Icons.favorite;
      case TipoNotificacao.comentario:
        return Icons.chat_bubble;
      case TipoNotificacao.mensagem:
        return Icons.send;
      case TipoNotificacao.sistema:
        return Icons.info;
    }
  }

  Color _corDoTipo(TipoNotificacao tipo, AppColors colors) {
    switch (tipo) {
      case TipoNotificacao.seguindo:
        return colors.primary;
      case TipoNotificacao.curtida:
        return colors.danger;
      case TipoNotificacao.comentario:
        return colors.success;
      case TipoNotificacao.mensagem:
        return const Color(0xFF9C27B0);
      case TipoNotificacao.sistema:
        return colors.textSecondary;
    }
  }
}
