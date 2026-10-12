import 'package:flutter/material.dart';

import '../data/sobre_conteudo.dart';
import 'widgets/sobre_hero.dart';
import 'widgets/sobre_timeline.dart';

class SobrePage extends StatelessWidget {
  const SobrePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre Nós')),
      body: const SafeArea(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SobreHero(),
              SobreTimeline(marcos: marcosCronograma),
            ],
          ),
        ),
      ),
    );
  }
}
