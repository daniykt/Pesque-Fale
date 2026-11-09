import 'package:flutter/material.dart';

import '../../../../core/router/rota_detalhe_publicacao.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../visualizacao_post/presentation/widgets/foto_publicacao.dart';
import '../../../visualizacao_post/presentation/widgets/linha_autor_publicacao.dart';
import '../../../visualizacao_post/presentation/widgets/tags_publicacao.dart';
import '../../domain/publicacao.dart';
import 'acoes_bar.dart';
import 'comentarios_sheet.dart';
import 'publicacao_menu_sheet.dart';

/// Card do feed no padrão do detalhe, mais compacto: autor (com o local
/// embaixo), texto, tags, foto 1:1 e ações. O card de local com estrelas
/// fica só no detalhe.
class PublicacaoCard extends StatelessWidget {
  const PublicacaoCard({super.key, required this.publicacao});

  final Publicacao publicacao;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final p = publicacao;
    final temFoto = p.imagemUrl != null && p.imagemUrl!.trim().isNotEmpty;
    final temDescricao = p.descricao != null && p.descricao!.isNotEmpty;
    final temConteudo = temDescricao || p.tags.isNotEmpty || temFoto;
    // Sem foto, o texto é o conteúdo principal e fica maior.
    final estiloTexto = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: colors.textPrimary,
      fontSize: temFoto ? 16 : 18,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.mdRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinhaAutorPublicacao(
            publicacao: p,
            mostrarLocal: true,
            onMenu: () => PublicacaoMenuSheet.show(context, p),
          ),
          // Texto, tags e foto num alvo só, que abre o detalhe. Autor, ⋯ e
          // ações têm toque próprio.
          if (temConteudo)
            InkWell(
              key: const ValueKey('card-conteudo'),
              onTap: () => Navigator.pushNamed(
                context,
                rotaDetalhePublicacaoNome,
                arguments: p,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (temDescricao)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        0,
                        AppSpacing.sm,
                        AppSpacing.xs,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(p.descricao!, style: estiloTexto),
                      ),
                    ),
                  if (p.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        0,
                        AppSpacing.sm,
                        AppSpacing.xs,
                      ),
                      child: TagsPublicacao(tags: p.tags),
                    ),
                  if (temFoto)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxs),
                      child: FotoPublicacao(url: p.imagemUrl!),
                    ),
                ],
              ),
            ),
          AcoesBar(
            publicacao: p,
            onComentarTap: () => ComentariosSheet.show(context, p),
          ),
        ],
      ),
    );
  }
}
