import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/cloudinary_url.dart';
import '../../domain/evento.dart';
import '../../providers/feed_provider.dart';

class EventoCard extends StatelessWidget {
  const EventoCard({super.key, required this.evento});

  final Evento evento;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final temFoto = evento.imagemUrl != null && evento.imagemUrl!.isNotEmpty;

    final descricao = evento.descricao?.trim() ?? '';

    return InkWell(
      onTap: () => _abrirDetalhe(context),
      borderRadius: AppRadius.mdRadius,
      child: SizedBox(
        height: 300,
        child: ClipRRect(
          borderRadius: AppRadius.mdRadius,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: colors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: temFoto
                        ? Image.network(
                            CloudinaryUrl.otimizar(
                              evento.imagemUrl!,
                              largura: 800,
                              altura: 320,
                            ),
                            fit: BoxFit.cover,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [colors.primary, colors.primaryAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.event,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryAccent.withValues(alpha: 0.15),
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Text(
                          _dataResumida(evento.dataInicio),
                          style: TextStyle(
                            color: colors.primaryAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        evento.titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              evento.localTexto ?? 'Local a definir',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (descricao.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          descricao,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirDetalhe(BuildContext context) async {
    final resultado = await Navigator.of(
      context,
    ).pushNamed<Object>('/evento/detalhe', arguments: evento);
    if (!context.mounted || resultado == null) return;
    final feed = context.read<FeedProvider>();
    if (resultado == true) {
      feed.removerEvento(evento.id);
    } else if (resultado is Evento) {
      feed.atualizarEvento(resultado);
    }
  }

  String _dataResumida(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(dt.day)}/${pad(dt.month)}';
  }
}
