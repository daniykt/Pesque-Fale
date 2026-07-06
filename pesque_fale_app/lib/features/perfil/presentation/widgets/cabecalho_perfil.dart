import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../auth/domain/usuario.dart';
import '../../data/perfil_exceptions.dart';
import '../../providers/perfil_provider.dart';
import 'acoes_header_perfil.dart';
import 'info_usuario.dart';

class CabecalhoPerfil extends StatefulWidget {
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

  static const fotoTamanho = 80.0;
  static const _fotoOffset = 40.0;

  @override
  State<CabecalhoPerfil> createState() => _CabecalhoPerfilState();
}

class _CabecalhoPerfilState extends State<CabecalhoPerfil> {
  static const _tamanhoMaximoBytes = 5 * 1024 * 1024;
  static const _formatosAceitos = {'jpg', 'jpeg', 'png', 'webp'};

  bool _enviandoFoto = false;
  bool _enviandoBanner = false;

  Future<void> _selecionarEEnviar({required bool banner}) async {
    final XFile? arquivo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (arquivo == null || !mounted) return;

    final extensao = arquivo.path.split('.').last.toLowerCase();
    if (!_formatosAceitos.contains(extensao)) {
      AppSnackbar.showError(context, const FormatoInvalidoException().message);
      return;
    }

    final tamanho = await arquivo.length();
    if (!mounted) return;
    if (tamanho > _tamanhoMaximoBytes) {
      AppSnackbar.showError(context, const FotoMuitoGrandeException().message);
      return;
    }

    setState(() {
      if (banner) {
        _enviandoBanner = true;
      } else {
        _enviandoFoto = true;
      }
    });

    final provider = context.read<PerfilProvider>();
    final arquivoLocal = File(arquivo.path);
    final ok = banner
        ? await provider.atualizarBanner(arquivoLocal)
        : await provider.atualizarFoto(arquivoLocal);

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
            if (widget.isOwnProfile && widget.onEditar != null && widget.onMenu != null)
              AcoesHeaderPerfil(
                onEditar: widget.onEditar!,
                onMenu: widget.onMenu!,
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
