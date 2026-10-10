import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({
    super.key,
    this.alturaSimbolo = 48,
    this.alturaNome = 40,
    this.espaco = 12,
  });

  final double alturaSimbolo;
  final double alturaNome;
  final double espaco;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cor = tema.brightness == Brightness.dark
        ? tema.extension<AppColors>()!.textPrimary
        : null;

    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/image/login/logo1.png',
            height: alturaSimbolo,
            color: cor,
          ),
          SizedBox(width: espaco),
          Image.asset(
            'assets/image/login/logo2.png',
            height: alturaNome,
            color: cor,
          ),
        ],
      ),
    );
  }
}