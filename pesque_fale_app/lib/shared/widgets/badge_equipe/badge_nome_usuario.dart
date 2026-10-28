import 'package:flutter/material.dart';

import 'badge_equipe.dart';
import 'tipo_badge.dart';

/// Nome do usuário seguido do [BadgeEquipe] quando o [userId] é da equipe.
///
/// Usa [Wrap] pra que, em telas estreitas, o badge desça pra linha de baixo
/// em vez de estourar a largura.
class BadgeNomeUsuario extends StatelessWidget {
  const BadgeNomeUsuario({
    super.key,
    required this.userId,
    required this.nome,
    this.tamanho = BadgeTamanho.md,
  });

  final String? userId;
  final Widget nome;
  final BadgeTamanho tamanho;

  @override
  Widget build(BuildContext context) {
    final tipo = resolverBadge(userId);
    if (tipo == null) return nome;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        nome,
        BadgeEquipe(tipo: tipo, tamanho: tamanho),
      ],
    );
  }
}
