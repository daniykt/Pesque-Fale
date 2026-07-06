import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../providers/perfil_provider.dart';

/// Botão contextual full-width: Nova Publicação (próprio perfil), Seguir,
/// ou Seguindo + Mensagem quando o chat já está liberado entre os dois.
class CtaPerfil extends StatefulWidget {
  const CtaPerfil({super.key});

  @override
  State<CtaPerfil> createState() => _CtaPerfilState();
}

class _CtaPerfilState extends State<CtaPerfil> {
  bool _carregando = false;

  Future<void> _seguir(PerfilProvider provider) async {
    setState(() => _carregando = true);
    final ok = await provider.seguir();
    if (!mounted) return;
    setState(() => _carregando = false);
    if (!ok) {
      AppSnackbar.showError(
        context,
        provider.errorMessage ?? 'Não foi possível seguir.',
      );
    }
  }

  Future<void> _deixarDeSeguir(PerfilProvider provider) async {
    setState(() => _carregando = true);
    final ok = await provider.deixarDeSeguir();
    if (!mounted) return;
    setState(() => _carregando = false);
    if (!ok) {
      AppSnackbar.showError(
        context,
        provider.errorMessage ?? 'Não foi possível deixar de seguir.',
      );
    }
  }

  void _abrirChat(PerfilProvider provider) {
    final chatId = provider.abrirChat();
    Navigator.pushNamed(context, '/chat', arguments: chatId);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PerfilProvider>();

    if (provider.isOwnProfile) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Nova Publicação'),
          onPressed: () => Navigator.pushNamed(context, '/publicar'),
        ),
      );
    }

    if (provider.isFollowing && provider.chatLiberado) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _carregando ? null : () => _deixarDeSeguir(provider),
              child: _carregando ? const _BotaoSpinner() : const Text('Seguindo'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FilledButton(
              onPressed: () => _abrirChat(provider),
              child: const Text('Mensagem'),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _carregando ? null : () => _seguir(provider),
        child: _carregando ? const _BotaoSpinner(branco: true) : const Text('Seguir'),
      ),
    );
  }
}

class _BotaoSpinner extends StatelessWidget {
  const _BotaoSpinner({this.branco = false});

  final bool branco;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      width: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: branco ? Colors.white : null,
      ),
    );
  }
}
