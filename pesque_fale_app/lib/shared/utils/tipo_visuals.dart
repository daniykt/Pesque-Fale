import 'package:flutter/material.dart';

import '../../features/pesquisa/domain/tipo_ponto.dart';

class TipoVisuals {
  TipoVisuals._();

  static IconData iconeDe(TipoPonto t) => switch (t) {
    TipoPonto.rio => Icons.waves,
    TipoPonto.lago => Icons.water_drop,
    TipoPonto.mar => Icons.sailing,
    TipoPonto.represa => Icons.hexagon_outlined,
    TipoPonto.pesqueiro => Icons.set_meal,
  };

  static Color corDe(TipoPonto t) => switch (t) {
    TipoPonto.rio => const Color(0xFF00ACC1),
    TipoPonto.lago => const Color(0xFF1976D2),
    TipoPonto.mar => const Color(0xFF0D47A1),
    TipoPonto.represa => const Color(0xFF546E7A),
    TipoPonto.pesqueiro => const Color(0xFF43A047),
  };
}
