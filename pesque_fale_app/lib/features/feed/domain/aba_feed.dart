import 'package:flutter/material.dart';

enum AbaFeed {
  paraVoce('para-voce', 'Para você', Icons.stars),
  seguindo('seguindo', 'Seguindo', Icons.group),
  eventos('eventos', 'Eventos', Icons.event),
  locais('locais', 'Locais', Icons.pin_drop),
  dicas('dicas', 'Dicas', Icons.lightbulb);

  const AbaFeed(this.id, this.label, this.icone);

  final String id;
  final String label;
  final IconData icone;
}
