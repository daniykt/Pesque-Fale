import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../providers/inbox_provider.dart';
import 'widgets/busca_conversas_bar.dart';
import 'widgets/empty_state_inbox.dart';
import 'widgets/erro_state_inbox.dart';
import 'widgets/inbox_skeleton.dart';
import 'widgets/item_conversa.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<InboxProvider>().carregar();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<InboxProvider>();
    if (provider.status == StatusInbox.carregado) {
      provider.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      body: SafeArea(
        child: Consumer<InboxProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Conversas',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
                if (provider.status == StatusInbox.carregado &&
                    provider.temAlgumaConversa)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: BuscaConversasBar(onChanged: provider.setTermoBusca),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Expanded(child: _buildConteudo(provider)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildConteudo(InboxProvider provider) {
    switch (provider.status) {
      case StatusInbox.carregando:
        return const InboxSkeleton();
      case StatusInbox.erro:
        return ErroStateInbox(onTentarNovamente: provider.carregar);
      case StatusInbox.carregado:
        if (!provider.temAlgumaConversa) return const EmptyStateInbox();

        final lista = provider.conversas;
        if (lista.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Nenhuma conversa encontrada para "${provider.termoBusca}"',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: lista.length,
            itemBuilder: (context, i) => ItemConversa(
              conversa: lista[i],
              onTap: () => AppSnackbar.showInfo(context, 'Chat em breve'),
            ),
          ),
        );
    }
  }
}
