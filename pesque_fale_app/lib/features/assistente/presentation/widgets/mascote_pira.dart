import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/widgets/auth_logo.dart';

class MascotePira extends StatefulWidget {
  const MascotePira({
    super.key,
    this.tamanho = 48,
    this.cor,
    this.animando = false,
  });

  static const nome = 'Pirá';

  final double tamanho;
  final Color? cor;
  final bool animando;

  @override
  State<MascotePira> createState() => _MascotePiraState();
}

class _MascotePiraState extends State<MascotePira>
    with SingleTickerProviderStateMixin {
  late final AnimationController _balanco = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animando) _balanco.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(MascotePira oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animando && !_balanco.isAnimating) {
      _balanco.repeat(reverse: true);
    } else if (!widget.animando && _balanco.isAnimating) {
      _balanco
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _balanco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cor =
        widget.cor ??
        (tema.brightness == Brightness.dark
            ? tema.extension<AppColors>()!.textPrimary
            : null);

    Widget peixe = Image.asset(
      'assets/image/login/logo1.png',
      height: widget.tamanho,
    );
    if (cor != null) {
      peixe = ColorFiltered(
        colorFilter: AuthLogo.filtroModoEscuro(cor),
        child: peixe,
      );
    }

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _balanco,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -widget.tamanho * 0.08 * _balanco.value),
          child: child,
        ),
        child: peixe,
      ),
    );
  }
}