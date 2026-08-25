import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/aba_feed.dart';
import '../domain/publicacao.dart';
import '../providers/feed_provider.dart';
import 'widgets/abas_scroll.dart';
import 'widgets/dicas_view.dart';
import 'widgets/eventos_carrossel.dart';
import 'widgets/locais_carrossel.dart';
import 'widgets/publicacao_card.dart';
import 'widgets/publicar_header_bar.dart';
import 'widgets/skeletons/carrossel_skeleton.dart';
import 'widgets/skeletons/publicacao_card_skeleton.dart';
import 'widgets/vazio_seguindo.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  @override
  void initState() {
    super.initState();
    // Dispara o carregamento inicial da aba padrão. O IndexedStack constrói
    // as 5 abas de uma vez, mas só a aba ativa deve buscar dados ao montar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FeedProvider>().trocarAba(AbaFeed.paraVoce);
    });
  }

  @override
  Widget build(BuildContext context) {
    final abaAtiva = context.watch<FeedProvider>().abaAtiva;

    return Scaffold(
      body: Column(
        children: [
          const PublicarHeaderBar(),
          const AbasScroll(),
          Expanded(
            child: IndexedStack(
              index: abaAtiva.index,
              children: const [
                _ParaVoceFeedView(),
                _SeguindoFeedView(),
                _EventosView(),
                _LocaisView(),
                DicasView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParaVoceFeedView extends StatelessWidget {
  const _ParaVoceFeedView();

  @override
  Widget build(BuildContext context) {
    final publicacoes = context.watch<FeedProvider>().paraVoce;
    return _FeedListaView(
      aba: AbaFeed.paraVoce,
      publicacoes: publicacoes,
      emptyBuilder: (context) =>
          _MensagemCentralizada(texto: 'Nenhuma publicação por aqui ainda.'),
    );
  }
}

class _SeguindoFeedView extends StatelessWidget {
  const _SeguindoFeedView();

  @override
  Widget build(BuildContext context) {
    final logado = context.watch<AuthProvider>().usuario != null;
    if (!logado) return const _CtaLogin();

    final publicacoes = context.watch<FeedProvider>().seguindo;
    return _FeedListaView(
      aba: AbaFeed.seguindo,
      publicacoes: publicacoes,
      emptyBuilder: (context) => const VazioSeguindo(),
    );
  }
}

class _EventosView extends StatelessWidget {
  const _EventosView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();
    final estado = provider.estadoDe(AbaFeed.eventos);

    switch (estado.status) {
      case StatusAba.inicial:
        // Aba ainda não foi aberta — IndexedStack já a mantém montada, mas
        // sem conteúdo animado enquanto ela não é a aba ativa.
        return const SizedBox.shrink();
      case StatusAba.carregando:
        return const SingleChildScrollView(
          padding: EdgeInsets.only(top: 16),
          child: CarrosselSkeleton(),
        );
      case StatusAba.erro:
        return _ErroView(
          mensagem: estado.mensagemErro,
          onRetry: provider.pullRefresh,
        );
      case StatusAba.vazio:
        return const _MensagemCentralizada(texto: 'Nenhum evento no momento.');
      case StatusAba.sucesso:
      case StatusAba.carregandoMais:
        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, bottom: 24),
          child: EventosCarrossel(eventos: provider.eventos),
        );
    }
  }
}

class _LocaisView extends StatelessWidget {
  const _LocaisView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();
    final estado = provider.estadoDe(AbaFeed.locais);

    switch (estado.status) {
      case StatusAba.inicial:
        return const SizedBox.shrink();
      case StatusAba.carregando:
        return const SingleChildScrollView(
          padding: EdgeInsets.only(top: 16),
          child: CarrosselSkeleton(),
        );
      case StatusAba.erro:
        return _ErroView(
          mensagem: estado.mensagemErro,
          onRetry: provider.pullRefresh,
        );
      case StatusAba.vazio:
        return const _MensagemCentralizada(
          texto: 'Nenhum local avaliado ainda.',
        );
      case StatusAba.sucesso:
      case StatusAba.carregandoMais:
        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, bottom: 24),
          child: LocaisCarrossel(pontos: provider.topLocais),
        );
    }
  }
}

/// Lista com pull-to-refresh e scroll infinito, compartilhada pelas abas
/// Para você e Seguindo.
class _FeedListaView extends StatefulWidget {
  const _FeedListaView({
    required this.aba,
    required this.publicacoes,
    required this.emptyBuilder,
  });

  final AbaFeed aba;
  final List<Publicacao> publicacoes;
  final WidgetBuilder emptyBuilder;

  @override
  State<_FeedListaView> createState() => _FeedListaViewState();
}

class _FeedListaViewState extends State<_FeedListaView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      context.read<FeedProvider>().carregarMais();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();
    final estado = provider.estadoDe(widget.aba);

    Widget conteudo;
    switch (estado.status) {
      case StatusAba.inicial:
        // Aba ainda não foi aberta — sem conteúdo animado enquanto ela não
        // é a aba ativa dentro do IndexedStack.
        conteudo = const SizedBox.shrink();
        break;
      case StatusAba.carregando:
        conteudo = ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, _) => const PublicacaoCardSkeleton(),
        );
        break;
      case StatusAba.erro:
        conteudo = _scrollableCentro(
          _ErroView(
            mensagem: estado.mensagemErro,
            onRetry: provider.pullRefresh,
          ),
        );
        break;
      case StatusAba.vazio:
        conteudo = _scrollableCentro(widget.emptyBuilder(context));
        break;
      case StatusAba.sucesso:
      case StatusAba.carregandoMais:
        final estaCarregandoMais = estado.status == StatusAba.carregandoMais;
        conteudo = ListView.separated(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: widget.publicacoes.length + (estaCarregandoMais ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            if (index >= widget.publicacoes.length) {
              return const PublicacaoCardSkeleton();
            }
            return PublicacaoCard(publicacao: widget.publicacoes[index]);
          },
        );
        break;
    }

    return RefreshIndicator(onRefresh: provider.pullRefresh, child: conteudo);
  }

  Widget _scrollableCentro(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [SizedBox(height: constraints.maxHeight, child: child)],
      ),
    );
  }
}

class _ErroView extends StatelessWidget {
  const _ErroView({required this.mensagem, required this.onRetry});

  final String? mensagem;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.danger),
            const SizedBox(height: 12),
            Text(
              mensagem ?? 'Não foi possível carregar o conteúdo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MensagemCentralizada extends StatelessWidget {
  const _MensagemCentralizada({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.textSecondary),
      ),
    );
  }
}

class _CtaLogin extends StatelessWidget {
  const _CtaLogin();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: colors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Faça login pra ver seu feed',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Acompanhe as publicações de quem você segue.',
              style: TextStyle(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
