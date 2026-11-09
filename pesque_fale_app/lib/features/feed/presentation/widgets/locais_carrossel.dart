import 'package:flutter/material.dart';

import '../../../pesquisa/domain/ponto.dart';
import 'local_card_compacto.dart';

class LocaisCarrossel extends StatelessWidget {
  const LocaisCarrossel({super.key, required this.pontos});

  final List<Ponto> pontos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Locais mais bem avaliados',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: pontos.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: LocalCardCompacto(ponto: pontos[i]),
            ),
          ),
        ),
      ],
    );
  }
}
