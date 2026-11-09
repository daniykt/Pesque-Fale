import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/cloudinary_url.dart';
import '../../data/perfil_api_client.dart';

/// Tile de usuário usado na lista de seguidores/seguindo. Mostra avatar com
/// fallback de iniciais, nome + @username e, à direita, botão de follow
/// inline — exceto para o próprio viewer e para itens cujo estado de
/// `souSeguidor` seja desconhecido (viewer anônimo).
class ItemRelacionamento extends StatelessWidget {
  const ItemRelacionamento({
    super.key,
    required this.usuario,
    required this.ehProprioViewer,
    required this.emProcessamento,
    required this.onTap,
    required this.onSeguir,
    required this.onDeixarDeSeguir,
  });

  final UsuarioResumido usuario;
  final bool ehProprioViewer;
  final bool emProcessamento;
  final VoidCallback onTap;
  final VoidCallback onSeguir;
  final VoidCallback onDeixarDeSeguir;

  static const double _raioAvatar = 22;

  // Paleta derivada do nome — mesmo esquema de `AvatarComTipo` pra manter
  // consistência visual com a tela de notificações.
  static const List<Color> _coresIniciais = [
    Color(0xFF0369A1),
    Color(0xFF15803D),
    Color(0xFFC2410C),
    Color(0xFF7E22CE),
    Color(0xFFBE185D),
    Color(0xFF0F766E),
    Color(0xFFA16207),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final fotoOtimizada = CloudinaryUrl.avatar(usuario.fotoPerfil, tamanho: 96);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: _raioAvatar,
              backgroundColor: _corIniciais(usuario.nome),
              backgroundImage: fotoOtimizada != null
                  ? NetworkImage(fotoOtimizada)
                  : null,
              child: fotoOtimizada == null
                  ? Text(
                      _iniciais(usuario.nome),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (usuario.username != null && usuario.username!.isNotEmpty)
                    Text(
                      '@${usuario.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (!ehProprioViewer && usuario.souSeguidor != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _BotaoRelacao(
                souSeguidor: usuario.souSeguidor!,
                emProcessamento: emProcessamento,
                onSeguir: onSeguir,
                onDeixarDeSeguir: onDeixarDeSeguir,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _iniciais(String nome) {
    final n = nome.trim();
    if (n.isEmpty) return '?';
    final partes = n.split(RegExp(r'\s+'));
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1))
        .toUpperCase();
  }

  Color _corIniciais(String nome) {
    final indice = nome.isEmpty
        ? 0
        : nome.codeUnits.reduce((a, b) => a + b);
    return _coresIniciais[indice % _coresIniciais.length];
  }
}

class _BotaoRelacao extends StatelessWidget {
  const _BotaoRelacao({
    required this.souSeguidor,
    required this.emProcessamento,
    required this.onSeguir,
    required this.onDeixarDeSeguir,
  });

  final bool souSeguidor;
  final bool emProcessamento;
  final VoidCallback onSeguir;
  final VoidCallback onDeixarDeSeguir;

  @override
  Widget build(BuildContext context) {
    final conteudo = emProcessamento
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(souSeguidor ? 'Seguindo' : 'Seguir');

    final onPressed = emProcessamento
        ? null
        : (souSeguidor ? onDeixarDeSeguir : onSeguir);

    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(100, 36)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      textStyle: WidgetStatePropertyAll(
        Theme.of(context).textTheme.labelLarge,
      ),
    );

    if (souSeguidor) {
      return OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: conteudo,
      );
    }
    return FilledButton(onPressed: onPressed, style: style, child: conteudo);
  }
}
