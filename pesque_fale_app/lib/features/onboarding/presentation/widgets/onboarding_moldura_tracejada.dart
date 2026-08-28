import 'package:flutter/material.dart';

// TODO: converter para um pacote de borda tracejada quando for aprovado
// como dependência do projeto — por ora, desenhado manualmente com
// CustomPainter para não introduzir dependência nova.
class OnboardingMolduraTracejada extends StatelessWidget {
  const OnboardingMolduraTracejada({
    super.key,
    required this.child,
    required this.corBorda,
    this.borderRadius = 0,
    this.tracoComprimento = 6,
    this.tracoEspacamento = 4,
    this.espessura = 2,
  });

  final Widget child;
  final Color corBorda;
  final double borderRadius;
  final double tracoComprimento;
  final double tracoEspacamento;
  final double espessura;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        cor: corBorda,
        borderRadius: borderRadius,
        tracoComprimento: tracoComprimento,
        tracoEspacamento: tracoEspacamento,
        espessura: espessura,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.cor,
    required this.borderRadius,
    required this.tracoComprimento,
    required this.tracoEspacamento,
    required this.espessura,
  });

  final Color cor;
  final double borderRadius;
  final double tracoComprimento;
  final double tracoEspacamento;
  final double espessura;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessura;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distancia = 0.0;
      while (distancia < metric.length) {
        final fim = (distancia + tracoComprimento).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distancia, fim), paint);
        distancia += tracoComprimento + tracoEspacamento;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.cor != cor ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.espessura != espessura;
}
