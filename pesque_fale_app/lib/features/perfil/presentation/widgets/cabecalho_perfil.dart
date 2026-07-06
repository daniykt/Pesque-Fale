import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/domain/usuario.dart';
import 'acoes_header_perfil.dart';
import 'info_usuario.dart';

class CabecalhoPerfil extends StatelessWidget {
  const CabecalhoPerfil({
    super.key,
    required this.usuario,
    required this.isOwnProfile,
    this.onEditar,
    this.onMenu,
  });

  final Usuario usuario;
  final bool isOwnProfile;
  final VoidCallback? onEditar;
  final VoidCallback? onMenu;

  static const _fotoTamanho = 80.0;
  static const _fotoOffset = 40.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: usuario.temBanner
                  ? Image.network(usuario.banner!, fit: BoxFit.cover)
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [colors.primary, colors.surface],
                        ),
                      ),
                    ),
            ),
            if (isOwnProfile && onEditar != null && onMenu != null)
              AcoesHeaderPerfil(onEditar: onEditar!, onMenu: onMenu!),
            Positioned(
              bottom: -_fotoOffset,
              left: AppSpacing.md,
              child: _FotoPerfil(usuario: usuario, colors: colors),
            ),
          ],
        ),
        const SizedBox(height: _fotoOffset),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: InfoUsuario(usuario: usuario),
        ),
      ],
    );
  }
}

class _FotoPerfil extends StatelessWidget {
  const _FotoPerfil({required this.usuario, required this.colors});

  final Usuario usuario;
  final AppColors colors;

  static const _tamanho = CabecalhoPerfil._fotoTamanho;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _tamanho,
      height: _tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        color: colors.primary,
        image: usuario.temFoto
            ? DecorationImage(
                image: NetworkImage(usuario.fotoPerfil!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: usuario.temFoto
          ? null
          : Text(
              usuario.nome.isNotEmpty ? usuario.nome[0].toUpperCase() : '?',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
              ),
            ),
    );
  }
}
