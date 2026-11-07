import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'mascote_pira.dart';

/// Botão flutuante que abre o assistente. Em [compacto] vira um círculo de
/// 56 px só com o mascote (o [Tooltip] passa a ser o rótulo acessível).
class BotaoAjudaAssistente extends StatelessWidget {
  const BotaoAjudaAssistente({super.key, this.compacto = false});

  final bool compacto;

  /// Espaço no fim das listas para o último item não ficar embaixo do
  /// botão: 56 do FAB + 16 de margem + folga.
  static const double espacoInferiorListas = AppSpacing.xxl + AppSpacing.xl;

  static const double _tamanhoMascote = 28;
  static const double _tamanhoCompacto = 56;

  // Expandido: valores padrão do FAB estendido do Material 3.
  static const double _paddingInicioExpandido = 16;
  static const double _paddingFimExpandido = 20;
  static const double _espacoRotuloExpandido = 8;

  // Compacto: 14 + 28 + 14 = 56, sem espaço nem rótulo.
  static const double _paddingCompacto =
      (_tamanhoCompacto - _tamanhoMascote) / 2;

  static const _duracao = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    // t vai de 1 (expandido) a 0 (compacto). Tudo deriva dele para que
    // largura, padding e opacidade se movam juntos numa animação só.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: compacto ? 0 : 1),
      duration: _duracao,
      curve: Curves.easeInOutCubic,
      builder: (context, t, _) {
        return FloatingActionButton.extended(
          heroTag: 'botao-ajuda-assistente',
          tooltip: 'Abrir o ${MascotePira.nome}, assistente virtual',
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          extendedIconLabelSpacing: _espacoRotuloExpandido * t,
          extendedPadding: EdgeInsetsDirectional.only(
            start: _lerp(_paddingCompacto, _paddingInicioExpandido, t),
            end: _lerp(_paddingCompacto, _paddingFimExpandido, t),
          ),
          onPressed: () => Navigator.of(context).pushNamed('/assistente'),
          // O desenho do mascote não é quadrado: o slot fixo garante o
          // círculo de 56 px no modo compacto.
          icon: const SizedBox.square(
            dimension: _tamanhoMascote,
            child: Center(
              child: MascotePira(tamanho: _tamanhoMascote, cor: Colors.white),
            ),
          ),
          label: t == 0 ? const SizedBox.shrink() : _Rotulo(t: t),
        );
      },
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

/// "Ajuda" que encolhe da direita para a esquerda e desaparece antes de a
/// largura chegar a zero.
class _Rotulo extends StatelessWidget {
  const _Rotulo({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: Curves.easeIn.transform(t),
      child: ClipRect(
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: t,
          child: const Text(
            'Ajuda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
