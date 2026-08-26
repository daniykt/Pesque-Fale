import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/publicacoes_repository.dart';
import '../../domain/publicacao.dart';
import '../../providers/feed_provider.dart';

class PublicacaoMenuSheet {
  PublicacaoMenuSheet._();

  static void show(
    BuildContext context,
    Publicacao publicacao, {
    VoidCallback? onDeleted,
  }) {
    final feedProvider = context.read<FeedProvider>();
    final publicacoesRepo = context.read<PublicacoesRepository>();
    final authProvider = context.read<AuthProvider>();
    final ehMinha = publicacao.autorId == authProvider.usuario?.id;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ehMinha)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Excluir publicação',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final confirmou = await _confirmarExclusao(context);
                  if (confirmou != true) return;
                  try {
                    await publicacoesRepo.deletar(publicacao.id);
                    feedProvider.removerPublicacao(publicacao.id);
                    if (context.mounted) {
                      AppSnackbar.showSuccess(context, 'Publicação excluída.');
                    }
                    onDeleted?.call();
                  } catch (_) {
                    if (context.mounted) {
                      AppSnackbar.showError(
                        context,
                        'Não foi possível excluir a publicação.',
                      );
                    }
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copiar link'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final url = 'https://pesqueefale.com.br/p/${publicacao.id}';
                await Clipboard.setData(ClipboardData(text: url));
                if (context.mounted) {
                  AppSnackbar.showSuccess(context, 'Link copiado');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Compartilhar'),
              onTap: () {
                Navigator.pop(sheetContext);
                final texto =
                    'Confira a publicação de ${publicacao.autorNome} no Pesque & Fale'
                    '${publicacao.descricao != null && publicacao.descricao!.isNotEmpty ? ": ${publicacao.descricao}" : ""}';
                Share.share(texto);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Denunciar'),
              onTap: () {
                Navigator.pop(sheetContext);
                AppSnackbar.showInfo(context, 'Denúncia registrada.');
              },
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> _confirmarExclusao(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir publicação'),
        content: const Text(
          'Tem certeza que deseja excluir esta publicação? Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Excluir', style: TextStyle(color: colors.danger)),
          ),
        ],
      ),
    );
  }
}
