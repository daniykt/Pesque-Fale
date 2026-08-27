import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_snackbar.dart';
import '../../chat/domain/conversa.dart';
import '../domain/notificacao.dart';
import '../providers/badge_notificacoes_provider.dart';
import '../providers/notificacoes_provider.dart';
import 'widgets/empty_state_notificacoes.dart';
import 'widgets/erro_state_notificacoes.dart';
import 'widgets/filtro_chips.dart';
import 'widgets/item_notificacao.dart';
import 'widgets/skeleton_notificacoes.dart';

class NotificacoesPage extends StatefulWidget {
  const NotificacoesPage({super.key});

  @override
  State<NotificacoesPage> createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends State<NotificacoesPage> {
  final Set<String> _destaqueSessao = {};
  bool _capturouDestaque = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<NotificacoesProvider>();
      await provider.carregar();
      if (!mounted) return;
      _capturarDestaque(provider);
      context.read<BadgeNotificacoesProvider>().zerar();
    });
  }

  void _capturarDestaque(NotificacoesProvider provider) {
    if (_capturouDestaque) return;
    _capturouDestaque = true;
    _destaqueSessao.addAll(
      provider.notificacoes.where((n) => !n.lida).map((n) => n.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<NotificacoesProvider>(
          builder: (context, provider, _) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: FiltroChips(
                  selecionado: provider.filtro,
                  onSelecionar: provider.setFiltro,
                ),
              ),
              Expanded(child: _buildConteudo(provider)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConteudo(NotificacoesProvider provider) {
    switch (provider.status) {
      case StatusNotificacoes.carregando:
        return const SkeletonNotificacoes();
      case StatusNotificacoes.erro:
        return ErroStateNotificacoes(onTentarNovamente: provider.carregar);
      case StatusNotificacoes.carregado:
        if (!provider.temAlguma) {
          return const EmptyStateNotificacoes(comFiltro: false);
        }
        final lista = provider.notificacoes;
        if (lista.isEmpty) {
          return const EmptyStateNotificacoes(comFiltro: true);
        }
        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final n = lista[i];
              return ItemNotificacao(
                notif: n,
                destacar: _destaqueSessao.contains(n.id),
                onTap: () => _navegar(n, provider),
                onSeguirDeVolta: () => provider.seguirDeVolta(n),
              );
            },
          ),
        );
    }
  }

  void _navegar(Notificacao n, NotificacoesProvider provider) {
    provider.marcarLidaLocal(n.id);
    switch (n.tipo) {
      case TipoNotificacao.seguindo:
        if (n.deId != null) {
          Navigator.of(context).pushNamed('/perfil', arguments: n.deId);
        }
        break;
      case TipoNotificacao.curtida:
      case TipoNotificacao.comentario:
        if (n.postId != null) {
          Navigator.of(
            context,
          ).pushNamed('/publicacao/detalhe', arguments: n.postId);
        }
        break;
      case TipoNotificacao.mensagem:
        if (n.deId != null) {
          final conversa = Conversa(
            id: n.chatId ?? '',
            outroId: n.deId!,
            outroNome: n.de ?? 'Usuário',
            outroUsername: n.deUsername ?? '',
            outroFoto: n.deFoto,
            ultimaMensagem: null,
            ultimaMensagemEm: null,
            naoLidas: 0,
            criadoEm: n.criadoEm,
          );
          Navigator.of(
            context,
          ).pushNamed('/chat/conversa', arguments: conversa);
        }
        break;
      case TipoNotificacao.sistema:
        AppSnackbar.showInfo(context, 'Notificação de sistema');
        break;
    }
  }
}
