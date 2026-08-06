import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../domain/publicacao.dart';
import '../../providers/feed_provider.dart';

class AcoesBar extends StatefulWidget {
  const AcoesBar({
    super.key,
    required this.publicacao,
    required this.onComentarTap,
  });

  final Publicacao publicacao;
  final VoidCallback onComentarTap;

  @override
  State<AcoesBar> createState() => _AcoesBarState();
}

class _AcoesBarState extends State<AcoesBar> {
  bool _curtindo = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final p = widget.publicacao;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text(
                '${p.curtidasCount} curtida${p.curtidasCount != 1 ? 's' : ''}',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: widget.onComentarTap,
                child: Text(
                  '${p.comentariosCount} comentário${p.comentariosCount != 1 ? 's' : ''}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.border),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AcaoBotao(
                icon: p.jaCurtiu ? Icons.favorite : Icons.favorite_border,
                cor: p.jaCurtiu ? Colors.red[400]! : colors.primary,
                label: p.jaCurtiu ? 'Curtido' : 'Curtir',
                onTap: _curtindo ? null : _curtir,
              ),
              _AcaoBotao(
                icon: Icons.chat_bubble_outline,
                cor: colors.primary,
                label: 'Comentar',
                onTap: widget.onComentarTap,
              ),
              _AcaoBotao(
                icon: Icons.share,
                cor: colors.primary,
                label: 'Compartilhar',
                onTap: _compartilhar,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _curtir() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.usuario == null) {
      AppSnackbar.showInfo(context, 'Faça login para interagir');
      return;
    }

    setState(() => _curtindo = true);
    try {
      await context.read<FeedProvider>().curtirOuDescurtir(widget.publicacao);
    } catch (_) {
      if (mounted) AppSnackbar.showError(context, 'Não foi possível curtir');
    } finally {
      if (mounted) setState(() => _curtindo = false);
    }
  }

  void _compartilhar() {
    final p = widget.publicacao;
    final texto =
        'Confira a publicação de ${p.autorNome} no Pesque & Fale'
        '${p.descricao != null && p.descricao!.isNotEmpty ? ": ${p.descricao}" : ""}';
    Share.share(texto);
  }
}

class _AcaoBotao extends StatelessWidget {
  const _AcaoBotao({
    required this.icon,
    required this.cor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color cor;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: cor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: cor, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
