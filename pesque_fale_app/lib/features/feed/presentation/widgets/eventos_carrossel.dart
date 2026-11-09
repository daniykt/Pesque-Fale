import 'package:flutter/material.dart';

import '../../domain/evento.dart';
import 'evento_card.dart';

class EventosCarrossel extends StatelessWidget {
  const EventosCarrossel({super.key, required this.eventos});

  final List<Evento> eventos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Próximos eventos',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: eventos.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: EventoCard(evento: eventos[i]),
            ),
          ),
        ),
      ],
    );
  }
}
