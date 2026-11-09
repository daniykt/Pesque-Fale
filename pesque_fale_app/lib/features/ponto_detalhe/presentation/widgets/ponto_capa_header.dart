import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/cloudinary_url.dart';
import '../../../../shared/utils/tipo_visuals.dart';
import '../../../pesquisa/domain/ponto.dart';

class PontoCapaHeader extends StatelessWidget {
  const PontoCapaHeader({super.key, required this.ponto});

  final Ponto ponto;

  @override
  Widget build(BuildContext context) {
    final temFoto = ponto.fotoCapa != null && ponto.fotoCapa!.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black38,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.black38,
            child: IconButton(
              icon: const Icon(Icons.ios_share, color: Colors.white),
              onPressed: () => Share.share(
                'Confira o ponto ${ponto.nome} em ${ponto.cidade}-${ponto.estado} no Pesque & Fale',
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          ponto.nome,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (temFoto)
              Image.network(
                CloudinaryUrl.coverCard(ponto.fotoCapa!),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(color: Colors.black12);
                },
                errorBuilder: (context, error, stackTrace) =>
                    _FallbackCapa(ponto: ponto),
              )
            else
              _FallbackCapa(ponto: ponto),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x99000000)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackCapa extends StatelessWidget {
  const _FallbackCapa({required this.ponto});

  final Ponto ponto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final cor = TipoVisuals.corDe(ponto.tipo);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cor, colors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          TipoVisuals.iconeDe(ponto.tipo),
          color: Colors.white,
          size: 64,
        ),
      ),
    );
  }
}
