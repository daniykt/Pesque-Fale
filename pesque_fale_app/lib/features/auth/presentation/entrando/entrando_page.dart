import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/auth_logo.dart';

class EntrandoPage extends StatefulWidget {
  const EntrandoPage({
    super.key,
    required this.preparar,
    this.duracaoMinima = const Duration(milliseconds: 800),
    this.avisoDemora = const Duration(milliseconds: 2500),
    this.limite = const Duration(seconds: 10),
  });

  final Future<void> Function() preparar;
  final Duration duracaoMinima;
  final Duration avisoDemora;
  final Duration limite;

  static const chaveBarra = Key('entrando-barra-progresso');

  @override
  State<EntrandoPage> createState() => _EntrandoPageState();
}

class _EntrandoPageState extends State<EntrandoPage>
    with TickerProviderStateMixin {
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _opacidade = CurvedAnimation(
    parent: _entrada,
    curve: Curves.easeOut,
  );
  late final Animation<double> _escalaEntrada = Tween<double>(
    begin: 0.85,
    end: 1,
  ).animate(CurvedAnimation(parent: _entrada, curve: Curves.easeOutBack));
  late final Animation<double> _escalaPulso = Tween<double>(
    begin: 1,
    end: 1.04,
  ).animate(CurvedAnimation(parent: _pulso, curve: Curves.easeInOut));
  late final AnimationController _progresso = AnimationController(vsync: this);

  Timer? _timerAviso;
  bool _mostrarAviso = false;

  @override
  void initState() {
    super.initState();
    _entrada.forward().whenComplete(() {
      if (mounted) _pulso.repeat(reverse: true);
    });
    _timerAviso = Timer(widget.avisoDemora, () {
      if (mounted) setState(() => _mostrarAviso = true);
    });
    _progresso.animateTo(
      0.9,
      duration: widget.limite,
      curve: Curves.easeOutCubic,
    );
    _entrar();
  }

  @override
  void dispose() {
    _timerAviso?.cancel();
    _entrada.dispose();
    _pulso.dispose();
    _progresso.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    await Future.wait([
      Future<void>.delayed(widget.duracaoMinima),
      _prepararComLimite(),
    ]);
    if (!mounted) return;
    _timerAviso?.cancel();
    await _progresso.animateTo(
      1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  Future<void> _prepararComLimite() async {
    try {
      await widget.preparar().timeout(widget.limite);
    } catch (_) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.background,
        body: Semantics(
          label: 'Entrando no Pesque & Fale',
          liveRegion: true,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _opacidade,
                  child: ScaleTransition(
                    scale: _escalaEntrada,
                    child: ScaleTransition(
                      scale: _escalaPulso,
                      child: const AuthLogo(
                        alturaSimbolo: 72,
                        alturaNome: 60,
                        espaco: AppSpacing.md,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeTransition(
                  opacity: _opacidade,
                  child: _BarraProgresso(
                    key: EntrandoPage.chaveBarra,
                    progresso: _progresso,
                    cor: colors.primaryAccent,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 24,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _mostrarAviso
                        ? _AvisoQuaseLa(colors: colors)
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarraProgresso extends StatelessWidget {
  const _BarraProgresso({
    super.key,
    required this.progresso,
    required this.cor,
  });

  final Animation<double> progresso;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final borda = BorderRadius.circular(2);

    return SizedBox(
      width: 180,
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.2),
          borderRadius: borda,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            animation: progresso,
            builder: (context, _) => FractionallySizedBox(
              widthFactor: progresso.value,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: cor, borderRadius: borda),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvisoQuaseLa extends StatelessWidget {
  const _AvisoQuaseLa({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Quase lá…',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
    );
  }
}