import 'package:flutter/material.dart';

import 'evento_card_skeleton.dart';

class CarrosselSkeleton extends StatelessWidget {
  const CarrosselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        itemCount: 3,
        itemBuilder: (_, i) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: EventoCardSkeleton(),
        ),
      ),
    );
  }
}
