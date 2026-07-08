import 'package:flutter/material.dart';

import '../../../../shared/utils/tipo_visuals.dart';
import '../../domain/tipo_ponto.dart';

class PontoMarker extends StatelessWidget {
  const PontoMarker({
    super.key,
    required this.tipo,
    required this.isDestacado,
    required this.onTap,
  });

  final TipoPonto tipo;
  final bool isDestacado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cor = TipoVisuals.corDe(tipo);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isDestacado ? 1.3 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: cor, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(TipoVisuals.iconeDe(tipo), size: 20, color: cor),
        ),
      ),
    );
  }
}
