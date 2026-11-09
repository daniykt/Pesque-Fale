import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class SkeletonMensagens extends StatefulWidget {
  const SkeletonMensagens({super.key});

  static const bolhas = <({bool ehMinha, double largura, double altura})>[
    (ehMinha: false, largura: 0.55, altura: 40),
    (ehMinha: true, largura: 0.45, altura: 40),
    (ehMinha: false, largura: 0.7, altura: 64),
    (ehMinha: true, largura: 0.6, altura: 52),
    (ehMinha: false, largura: 0.4, altura: 40),
    (ehMinha: true, largura: 0.65, altura: 76),
  ];

  @override
  State<SkeletonMensagens> createState() => _SkeletonMensagensState();
}

class _SkeletonMensagensState extends State<SkeletonMensagens>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacidade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);
    _opacidade = Tween<double>(
      begin: 0.5,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Semantics(
      label: 'Carregando mensagens',
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: _opacidade,
          child: ListView(
            reverse: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            children: [
              for (final bolha in SkeletonMensagens.bolhas.reversed)
                _BolhaSkeleton(
                  ehMinha: bolha.ehMinha,
                  largura: bolha.largura,
                  altura: bolha.altura,
                  cor: colors.border,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BolhaSkeleton extends StatelessWidget {
  const _BolhaSkeleton({
    required this.ehMinha,
    required this.largura,
    required this.altura,
    required this.cor,
  });

  final bool ehMinha;
  final double largura;
  final double altura;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: ehMinha ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: largura,
        child: Container(
          height: altura,
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(ehMinha ? 16 : 4),
              bottomRight: Radius.circular(ehMinha ? 4 : 16),
            ),
          ),
        ),
      ),
    );
  }
}