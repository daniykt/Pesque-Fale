import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/imagem_placeholder.dart';
import '../../../feed/domain/publicacao.dart';

class GaleriaPerfil extends StatelessWidget {
  const GaleriaPerfil({
    super.key,
    required this.publicacoes,
    required this.isOwnProfile,
  });

  final List<Publicacao> publicacoes;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Semantics(
            header: true,
            child: Text(
              'Publicações',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        if (publicacoes.isEmpty)
          _EstadoVazio(isOwnProfile: isOwnProfile)
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: publicacoes.length,
            findChildIndexCallback: (key) {
              if (key is! ValueKey<String>) return null;
              final indice = publicacoes.indexWhere((p) => p.id == key.value);
              return indice == -1 ? null : indice;
            },
            itemBuilder: (context, index) => _ItemGaleria(
              key: ValueKey(publicacoes[index].id),
              publicacao: publicacoes[index],
              posicao: index + 1,
              total: publicacoes.length,
            ),
          ),
      ],
    );
  }
}

/// Rótulo do leitor de tela para um item da grade. Identifica o item pelo
/// começo da descrição; sem descrição, pela posição na grade.
@visibleForTesting
String rotuloItemGaleria(
  Publicacao publicacao, {
  required int posicao,
  required int total,
}) {
  const limite = 40;
  final descricao = (publicacao.descricao ?? '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (descricao.isEmpty) return 'Abrir publicação $posicao de $total';

  final letras = descricao.characters;
  if (letras.length <= limite) return 'Abrir publicação: $descricao';
  return 'Abrir publicação: ${letras.take(limite).toString().trimRight()}…';
}

class _ItemGaleria extends StatefulWidget {
  const _ItemGaleria({
    super.key,
    required this.publicacao,
    required this.posicao,
    required this.total,
  });

  final Publicacao publicacao;
  final int posicao;
  final int total;

  @override
  State<_ItemGaleria> createState() => _ItemGaleriaState();
}

class _ItemGaleriaState extends State<_ItemGaleria> {
  bool _pressionado = false;

  // Mesmo caminho do feed: o detalhe recebe a publicação já hidratada e abre
  // na hora, acompanhando o PublicacoesStore.
  void _abrirDetalhe() {
    Navigator.pushNamed(
      context,
      '/publicacao/detalhe',
      arguments: widget.publicacao,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagemUrl = widget.publicacao.imagemUrl;

    return Semantics(
      container: true,
      button: true,
      label: rotuloItemGaleria(
        widget.publicacao,
        posicao: widget.posicao,
        total: widget.total,
      ),
      child: GestureDetector(
        onLongPressStart: (_) => setState(() => _pressionado = true),
        onLongPressEnd: (_) => setState(() => _pressionado = false),
        child: _conteudo(imagemUrl),
      ),
    );
  }

  Widget _conteudo(String? imagemUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imagemUrl == null || imagemUrl.isEmpty)
          const ImagemIndisponivel(
            icone: Icons.image_not_supported_outlined,
            tamanhoIcone: 32,
            mostrarTexto: false,
          )
        else
          Image.network(
            imagemUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const ImagemCarregando(tamanhoIcone: 32);
            },
            errorBuilder: (context, error, stackTrace) =>
                const ImagemIndisponivel(tamanhoIcone: 32, mostrarTexto: false),
          ),
        if (_pressionado)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, color: Colors.white, size: 16),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  '${widget.publicacao.curtidasCount}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.mode_comment_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  '${widget.publicacao.comentariosCount}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        // Por cima da imagem para o ripple aparecer. O item é quadrado, então
        // o ripple também é.
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(onTap: _abrirDetalhe),
          ),
        ),
      ],
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio({required this.isOwnProfile});

  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.photo_camera_back_outlined,
            size: 48,
            color: colors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nenhuma publicação ainda',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          if (isOwnProfile) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/publicacao/nova'),
              child: const Text('Nova Publicação'),
            ),
          ],
        ],
      ),
    );
  }
}
