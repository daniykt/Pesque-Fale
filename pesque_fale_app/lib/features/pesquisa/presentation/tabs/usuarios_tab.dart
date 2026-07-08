import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../providers/pesquisa_usuarios_provider.dart';
import '../widgets/busca_bar.dart';
import '../widgets/skeletons/usuario_card_skeleton.dart';
import '../widgets/usuario_card.dart';

class UsuariosTab extends StatelessWidget {
  const UsuariosTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PesquisaUsuariosProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: BuscaBar(
            hintText: 'Buscar pescadores...',
            onChanged: provider.alterarBusca,
          ),
        ),
        Expanded(child: _Conteudo(provider: provider)),
      ],
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.provider});

  final PesquisaUsuariosProvider provider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    switch (provider.status) {
      case PesquisaUsuariosStatus.idle:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, size: 48, color: colors.textSecondary),
                const SizedBox(height: AppSpacing.sm),
                const Text('Digite o nome de um pescador para começar'),
              ],
            ),
          ),
        );
      case PesquisaUsuariosStatus.carregando:
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, _) => const UsuarioCardSkeleton(),
        );
      case PesquisaUsuariosStatus.vazio:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_off, size: 48, color: colors.textSecondary),
                const SizedBox(height: AppSpacing.sm),
                const Text('Nenhum pescador encontrado com esse nome'),
              ],
            ),
          ),
        );
      case PesquisaUsuariosStatus.erro:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colors.danger),
                const SizedBox(height: AppSpacing.sm),
                Text(provider.mensagemErro ?? 'Não foi possível buscar'),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  onPressed: provider.recarregar,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        );
      case PesquisaUsuariosStatus.sucesso:
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: provider.usuarios.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final usuario = provider.usuarios[index];
            return UsuarioCard(
              usuario: usuario,
              onVerPerfil: () => Navigator.pushNamed(
                context,
                '/perfil',
                arguments: usuario.id,
              ),
            );
          },
        );
    }
  }
}
