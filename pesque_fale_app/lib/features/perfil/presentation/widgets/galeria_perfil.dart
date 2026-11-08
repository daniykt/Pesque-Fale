import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/cloudinary_url.dart';
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
  final descricao = _descricaoNormalizada(publicacao.descricao);
  if (descricao.isEmpty) return 'Abrir publicação $posicao de $total';

  final letras = descricao.characters;
  if (letras.length <= limite) return 'Abrir publicação: $descricao';
  return 'Abrir publicação: ${letras.take(limite).toString().trimRight()}…';
}

/// Junta espaços e quebras de linha num espaço só, para o rótulo e para o
/// quadrado de texto não gastarem espaço com linhas em branco.
String _descricaoNormalizada(String? descricao) =>
    (descricao ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();

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
        // Sem foto é um post só de texto, não um erro. O ImagemIndisponivel
        // fica só para foto que falha ao carregar (errorBuilder abaixo).
        if (imagemUrl == null || imagemUrl.trim().isEmpty)
          _QuadradoTexto(descricao: widget.publicacao.descricao)
        else
          // Miniatura quadrada: ~120dp na grade × densidade 3.
          Image.network(
            CloudinaryUrl.otimizar(imagemUrl, largura: 360, altura: 360),
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

/// Item da grade para publicação sem foto: o começo da descrição num quadrado
/// de superfície, com um ícone discreto indicando que é um post de texto.
///
/// Fica fora da árvore de semântica: o rótulo do item já lê a descrição.
class _QuadradoTexto extends StatelessWidget {
  const _QuadradoTexto({required this.descricao});

  final String? descricao;

  static const _maxLinhas = 4;
  static const _tamanhoIcone = 16.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final texto = _descricaoNormalizada(descricao);
    final icone = Icon(
      Icons.notes,
      size: _tamanhoIcone,
      color: colors.textSecondary,
    );

    return ExcludeSemantics(
      child: ClipRect(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: texto.isEmpty
                ? Center(child: icone)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _TextoAjustado(texto: texto)),
                      const SizedBox(height: AppSpacing.xxs),
                      Align(alignment: Alignment.bottomRight, child: icone),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Até [_QuadradoTexto._maxLinhas] linhas, mas só as que cabem inteiras na
/// altura disponível. Assim a reticência aparece em vez de uma linha cortada
/// ao meio quando a fonte do sistema está grande.
class _TextoAjustado extends StatelessWidget {
  const _TextoAjustado({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final estilo = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: colors.textPrimary);
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final medidor = TextPainter(
          text: TextSpan(text: 'Ag', style: estilo),
          textDirection: textDirection,
          textScaler: textScaler,
          maxLines: 1,
        )..layout();
        final alturaLinha = medidor.height;
        medidor.dispose();

        final linhas = (constraints.maxHeight / alturaLinha).floor().clamp(
          1,
          _QuadradoTexto._maxLinhas,
        );

        return Text(
          texto,
          maxLines: linhas,
          overflow: TextOverflow.ellipsis,
          style: estilo,
        );
      },
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
