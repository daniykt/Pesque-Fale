import 'package:flutter/material.dart';

import 'clima_card.dart';
import 'dica_do_dia_card.dart';

class DicasView extends StatelessWidget {
  const DicasView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: const [ClimaCard(), SizedBox(height: 16), DicaDoDiaCard()],
      ),
    );
  }
}
