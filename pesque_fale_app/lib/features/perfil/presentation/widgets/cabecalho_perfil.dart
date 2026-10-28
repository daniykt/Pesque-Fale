import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/crop_imagem/crop_imagem_helper.dart';
import '../../../../shared/widgets/crop_imagem/modo_crop.dart';
import '../../../auth/domain/usuario.dart';
import '../../providers/perfil_provider.dart';
import 'info_usuario.dart';

class CabecalhoPerfil extends StatefulWidget {
  const CabecalhoPerfil({
    super.key,
    required this.usuario,
    required this.isOwnProfile,
  });

  final Usuario usuario;
  final bool isOwnProfile;

  static const fotoTamanho = 80.0;
  static const _fotoOffset = 40.0;

  @override
  State<CabecalhoPerfil> createState() => _CabecalhoPerfilState();
}

class _CabecalhoPerfilState extends State<CabecalhoPerfil> {
  bool _enviandoFoto = false;
  bool _enviandoBanner = false;

  Future<void> _selecionarEEnviar({required bool banner}) async {
    final modo = banner ? ModoCrop.banner : ModoCrop.avatar;
    final bytes = await CropImagemHelper.escolherECortar(
      context,
      modo: modo,
    );
    if (bytes == null || !mounted) return;

    setState(() {
      if (banner) {
        _enviandoBanner = true;
      } else {
        _enviandoFoto = true;
      }
    });

    final provider = context.read<PerfilProvider>();
    final filename = banner ? 'banner.jpg' : 'avatar.jpg';
    final ok = banner
        ? await provider.atualizarBanner(
            bytes,
            filename: filename,
            mimeType: 'image/jpeg',
          )
        : await provider.atualizarFoto(
            bytes,
            filename: filename,
            mimeType: 'image/jpeg',
          );

    if (!mounted) return;
    setState(() {
      if (banner) {
        _enviandoBanner = false;
      } else {
        _enviandoFoto = false;
      }
    });

    if (!ok) {
      AppSnackbar.showError(
        context,
        provider.errorMessage ?? 'Falha ao enviar imagem.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final usuario = widget.usuario;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: widget.isOwnProfile
                  ? () => _selecionarEEnviar(banner: true)
                  : null,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    usuario.temBanner
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
                    if (_enviandoBanner)
                      const ColoredBox(
                        color: Colors.black38,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -CabecalhoPerfil._fotoOffset,
              left: AppSpacing.md,
              child: GestureDetector(
                onTap: widget.isOwnProfile
                    ? () => _selecionarEEnviar(banner: false)
                    : null,
                child: _FotoPerfil(
                  usuario: usuario,
                  colors: colors,
                  enviando: _enviandoFoto,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: CabecalhoPerfil._fotoOffset),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: InfoUsuario(usuario: usuario),
        ),
      ],
    );
  }
}

class _FotoPerfil extends StatelessWidget {
  const _FotoPerfil({
    required this.usuario,
    required this.colors,
    this.enviando = false,
  });

  final Usuario usuario;
  final AppColors colors;
  final bool enviando;

  static const _tamanho = CabecalhoPerfil.fotoTamanho;

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
      child: enviando
          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
          : usuario.temFoto
          ? null
          : Text(
              usuario.nome.isNotEmpty ? usuario.nome[0].toUpperCase() : '?',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(color: Colors.white),
            ),
    );
  }
}
