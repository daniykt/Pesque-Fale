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

  static ColorFilter filtroModoEscuro(Color cor) => ColorFilter.matrix([
    0, 0, 0, 0, cor.r * 255,
    0, 0, 0, 0, cor.g * 255,
    0, 0, 0, 0, cor.b * 255,
    -0.2126, -0.7152, -0.0722, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/image/login/logo1.png', height: alturaSimbolo),
        SizedBox(width: espaco),
        Image.asset('assets/image/login/logo2.png', height: alturaNome),
      ],
    );

    return ExcludeSemantics(
      child: tema.brightness == Brightness.dark
          ? ColorFiltered(
              colorFilter: filtroModoEscuro(
                tema.extension<AppColors>()!.textPrimary,
              ),
              child: logo,
            )
          : logo,
    );
  }
}