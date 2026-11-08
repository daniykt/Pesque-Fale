import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'imagem_placeholder.dart';

/// Foto em tela cheia sobre fundo escuro, inteira (`BoxFit.contain`), com
/// zoom de pinça e botão de fechar. Fica escura nos dois temas.
class VisualizadorImagem extends StatelessWidget {
  const VisualizadorImagem({super.key, required this.imagem, this.descricao});

  final ImageProvider imagem;

  /// O que a foto mostra, para o leitor de tela.
  final String? descricao;

  /// Ícones claros na barra de status, sobre o fundo escuro.
  @visibleForTesting
  static const estiloBarraDeStatus = SystemUiOverlayStyle(
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  );

  static Future<void> abrir(
    BuildContext context,
    ImageProvider imagem, {
    String? descricao,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) =>
            VisualizadorImagem(imagem: imagem, descricao: descricao),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tema escuro para os placeholders e o botão seguirem os tokens escuros.
    return Theme(
      data: AppTheme.dark,
      child: Builder(
        builder: (context) {
          final colors = Theme.of(context).extension<AppColors>()!;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: estiloBarraDeStatus,
            child: Scaffold(
              backgroundColor: colors.background,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: Image(
                          image: imagem,
                          fit: BoxFit.contain,
                          semanticLabel: descricao,
                          frameBuilder: (context, child, frame, sincrono) {
                            if (frame == null && !sincrono) {
                              return const AspectRatio(
                                aspectRatio: 1,
                                child: ImagemCarregando(),
                              );
                            }
                            return child;
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const AspectRatio(
                                aspectRatio: 1,
                                child: ImagemIndisponivel(),
                              ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Semantics(
                          button: true,
                          label: 'Fechar foto',
                          onTap: () => Navigator.of(context).maybePop(),
                          excludeSemantics: true,
                          child: IconButton(
                            key: const ValueKey('visualizador-fechar'),
                            icon: Icon(Icons.close, color: colors.textPrimary),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
