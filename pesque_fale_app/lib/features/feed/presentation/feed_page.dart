import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../assistente/presentation/widgets/botao_ajuda_assistente.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/aba_feed.dart';
import '../domain/evento.dart';
import '../domain/publicacao.dart';
import '../providers/feed_provider.dart';
import 'widgets/abas_scroll.dart';
import 'widgets/dicas_view.dart';
import 'widgets/eventos_carrossel.dart';
import 'widgets/locais_carrossel.dart';
import 'widgets/novas_publicacoes_button.dart';
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
        return RefreshIndicator(
          onRefresh: provider.pullRefresh,
          child: _CentroRolavel(
            child: _ErroView(
              mensagem: estado.mensagemErro,
              onRetry: provider.pullRefresh,
            ),
          ),
        );
      case StatusAba.vazio:
        return RefreshIndicator(
          onRefresh: provider.pullRefresh,
          child: const _CentroRolavel(child: _EventosVazio()),
        );
      case StatusAba.sucesso:
      case StatusAba.carregandoMais:
        return RefreshIndicator(
          onRefresh: provider.pullRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              top: 16,
              bottom: BotaoAjudaAssistente.espacoInferiorListas,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _BotaoCriarEvento(rotulo: 'Criar evento'),
                ),
                EventosCarrossel(eventos: provider.eventos),
              ],
            ),
          ),
        );
    }
  }
}

class _EventosVazio extends StatelessWidget {
  const _EventosVazio();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textos = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_outlined, size: 56, color: colors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Nenhum evento programado por enquanto.',
            textAlign: TextAlign.center,
            style: textos.bodyLarge?.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 24),
          const _BotaoCriarEvento(rotulo: 'Criar o primeiro evento'),
        ],
      ),
    );
  }
}

class _BotaoCriarEvento extends StatelessWidget {
  const _BotaoCriarEvento({required this.rotulo});

  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => _criarEvento(context),
      icon: const Icon(Icons.add),
      label: Text(rotulo),
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Future<void> _criarEvento(BuildContext context) async {
    if (context.read<AuthProvider>().usuario == null) {
      Navigator.of(context).pushNamed('/login');
      return;
    }
    final feed = context.read<FeedProvider>();
    final criado = await Navigator.of(
      context,
    ).pushNamed<Object?>('/evento/novo');
    if (criado is Evento) feed.inserirEvento(criado);
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
        return RefreshIndicator(
          onRefresh: provider.pullRefresh,
          child: _CentroRolavel(
            child: _ErroView(
              mensagem: estado.mensagemErro,
              onRetry: provider.pullRefresh,
            ),
          ),
        );
      case StatusAba.vazio:
        return RefreshIndicator(
          onRefresh: provider.pullRefresh,
          child: const _CentroRolavel(
            child: _MensagemCentralizada(texto: 'Nenhum local avaliado ainda.'),
          ),
        );
      case StatusAba.sucesso:
      case StatusAba.carregandoMais:
        return RefreshIndicator(
          onRefresh: provider.pullRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              top: 16,
              bottom: BotaoAjudaAssistente.espacoInferiorListas,
            ),
            child: LocaisCarrossel(pontos: provider.topLocais),
          ),
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
  /// Até essa distância do topo o usuário conta como "no topo": publicações
  /// novas da aba Seguindo entram direto, sem chip.
  static const _limiteTopo = 100.0;

  final _scrollController = ScrollController();

  /// Guardado pra remover o listener no dispose sem consultar o context.
  late final FeedProvider _feedOuvido;

  bool get _estaNoTopo =>
      !_scrollController.hasClients || _scrollController.offset <= _limiteTopo;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _feedOuvido = context.read<FeedProvider>()
      ..addListener(_aplicarPendentesSeNoTopo);
  }

  @override
  void dispose() {
    _feedOuvido.removeListener(_aplicarPendentesSeNoTopo);
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
    // Voltou pro topo com o chip na tela: aplica e o chip some.
    _aplicarPendentesSeNoTopo();
  }

  /// Roda a cada notify do provider (não só quando os pendentes mudam) e a
  /// cada scroll; sai cedo quando não há pendente.
  void _aplicarPendentesSeNoTopo() {
    final feed = _feedOuvido;
    if (feed.pendentesCount(widget.aba) == 0) return;
    // Lista ainda não carregada/em erro: o próximo carregamento já zera.
    switch (feed.estadoDe(widget.aba).status) {
      case StatusAba.sucesso:
      case StatusAba.carregandoMais:
      case StatusAba.vazio:
        break;
      case StatusAba.inicial:
      case StatusAba.carregando:
      case StatusAba.erro:
        return;
    }
    if (_estaNoTopo) feed.aplicarPendentes(widget.aba);
  }

  Future<void> _irProTopoEAplicar() async {
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    // Normalmente o _onScroll já aplicou ao cruzar o limite; aí é no-op.
    await _feedOuvido.aplicarPendentes(widget.aba);
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
        conteudo = _CentroRolavel(
          child: _ErroView(
            mensagem: estado.mensagemErro,
            onRetry: provider.pullRefresh,
          ),
        );
        break;
      case StatusAba.vazio:
        conteudo = _CentroRolavel(child: widget.emptyBuilder(context));
        break;
      case StatusAba.sucesso:
      case StatusAba.carregandoMais:
        final estaCarregandoMais = estado.status == StatusAba.carregandoMais;
        final temRodape = estaCarregandoMais || estado.falhouCarregarMais;
        conteudo = ListView.separated(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            12,
            12,
            12,
            BotaoAjudaAssistente.espacoInferiorListas,
          ),
          itemCount: widget.publicacoes.length + (temRodape ? 1 : 0),
          findItemIndexCallback: (key) =>
              _indicePorChave(widget.publicacoes, key),
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            if (index >= widget.publicacoes.length) {
              return estado.falhouCarregarMais
                  ? _ErroCarregarMais(
                      onTentarDeNovo: provider.tentarCarregarMaisDeNovo,
                    )
                  : const PublicacaoCardSkeleton();
            }
            final publicacao = widget.publicacoes[index];
            return PublicacaoCard(
              key: ValueKey(publicacao.id),
              publicacao: publicacao,
            );
          },
        );
        break;
    }

    final mostraChip =
        (estado.status == StatusAba.sucesso ||
            estado.status == StatusAba.carregandoMais) &&
        provider.pendentesCount(widget.aba) > 0 &&
        !_estaNoTopo;

    return RefreshIndicator(
      onRefresh: provider.pullRefresh,
      child: Stack(
        children: [
          Positioned.fill(child: conteudo),
          if (mostraChip)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: NovasPublicacoesButton(
                  quantidade: provider.pendentesCount(widget.aba),
                  onTap: _irProTopoEAplicar,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

int? _indicePorChave(List<Publicacao> publicacoes, Key key) {
  if (key is! ValueKey<String>) return null;
  final indice = publicacoes.indexWhere((p) => p.id == key.value);
  return indice == -1 ? null : indice;
}

class _CentroRolavel extends StatelessWidget {
  const _CentroRolavel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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

class _ErroCarregarMais extends StatelessWidget {
  const _ErroCarregarMais({required this.onTentarDeNovo});

  final Future<void> Function() onTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, size: 32, color: colors.danger),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Não foi possível carregar mais publicações.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton.icon(
            onPressed: onTentarDeNovo,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              foregroundColor: colors.primaryAccent,
              side: BorderSide(color: colors.primaryAccent),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar de novo'),
          ),
        ],
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
