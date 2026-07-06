import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../shared/widgets/app_snackbar.dart';
import '../../../../auth/providers/auth_provider.dart';
import '../../../providers/editar_perfil_provider.dart';

/// Preview do banner com gradiente do `primary` quando vazio. Toque abre o
/// seletor de imagem (upload real só acontece ao salvar).
class CampoBanner extends StatelessWidget {
  const CampoBanner({super.key});

  Future<void> _escolher(BuildContext context) async {
    final provider = context.read<EditarPerfilProvider>();
    final ok = await provider.escolherBanner();
    if (!ok && provider.errorMessage != null && context.mounted) {
      AppSnackbar.showError(context, provider.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditarPerfilProvider>();
    final usuario = context.watch<AuthProvider>().usuario;
    final colors = Theme.of(context).extension<AppColors>()!;

    final previewLocal = provider.novoBannerPath;
    final bannerRemoto = usuario?.banner;

    return GestureDetector(
      onTap: () => _escolher(context),
      child: ClipRRect(
        borderRadius: AppRadius.mdRadius,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (previewLocal != null)
                Image.file(File(previewLocal), fit: BoxFit.cover)
              else if (bannerRemoto != null && bannerRemoto.isNotEmpty)
                Image.network(bannerRemoto, fit: BoxFit.cover)
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.primary,
                        Color.lerp(colors.primary, colors.surface, 0.4)!,
                      ],
                    ),
                  ),
                ),
              const Positioned(right: 12, bottom: 12, child: _BadgeCamera()),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeCamera extends StatelessWidget {
  const _BadgeCamera();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Colors.black45,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.camera_alt_outlined,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}
