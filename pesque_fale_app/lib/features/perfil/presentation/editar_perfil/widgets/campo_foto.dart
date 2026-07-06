import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/widgets/app_snackbar.dart';
import '../../../../auth/providers/auth_provider.dart';
import '../../../providers/editar_perfil_provider.dart';

/// Preview da foto de perfil com borda branca de 3px + elevação sutil.
/// Toque abre o seletor de imagem (upload real só acontece ao salvar).
class CampoFoto extends StatelessWidget {
  const CampoFoto({super.key, this.tamanho = 88});

  final double tamanho;

  Future<void> _escolher(BuildContext context) async {
    final provider = context.read<EditarPerfilProvider>();
    final ok = await provider.escolherFoto();
    if (!ok && provider.errorMessage != null && context.mounted) {
      AppSnackbar.showError(context, provider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditarPerfilProvider>();
    final usuario = context.watch<AuthProvider>().usuario;
    final colors = Theme.of(context).extension<AppColors>()!;

    final previewLocal = provider.novaFotoPath;
    final fotoRemota = usuario?.fotoPerfil;

    return GestureDetector(
      onTap: () => _escolher(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: colors.primary,
            shape: const CircleBorder(
              side: BorderSide(color: Colors.white, width: 3),
            ),
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: tamanho,
              height: tamanho,
              child: previewLocal != null
                  ? Image.file(File(previewLocal), fit: BoxFit.cover)
                  : (fotoRemota != null && fotoRemota.isNotEmpty)
                  ? Image.network(fotoRemota, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        usuario != null && usuario.nome.isNotEmpty
                            ? usuario.nome[0].toUpperCase()
                            : '?',
                        style: Theme.of(
                          context,
                        ).textTheme.displaySmall?.copyWith(color: Colors.white),
                      ),
                    ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
