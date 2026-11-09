import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/perfil_repository.dart';
import '../../providers/lista_relacionamentos_provider.dart';
import 'item_relacionamento.dart';

/// Modal bottom sheet com a lista de seguidores ou seguindo do perfil
/// visitado. Abre em 75% da altura, arrastável até 95%, mostra 20 itens por
/// página e carrega mais ao se aproximar do fim.
class ListaRelacionamentosSheet extends StatelessWidget {
  const ListaRelacionamentosSheet._({required this.perfilId, required this.tipo});

  final String perfilId;
  final TipoRelacionamento tipo;

  static Future<void> show(
    BuildContext context, {
    required String perfilId,
    required TipoRelacionamento tipo,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => ListaRelacionamentosSheet._(
        perfilId: perfilId,
        tipo: tipo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meuId = context.read<AuthProvider>().usuario?.id ?? '';
    final repository = context.read<PerfilRepository>();

    return ChangeNotifierProvider<ListaRelacionamentosProvider>(
      create: (_) => ListaRelacionamentosProvider(
        repository: repository,
        perfilId: perfilId,
        tipo: tipo,
        meuId: meuId,
      )..carregarInicial(),
      child: _ConteudoSheet(tipo: tipo, meuId: meuId),
    );
  }
}

class _ConteudoSheet extends StatelessWidget {
  const _ConteudoSheet({required this.tipo, required this.meuId});

  final TipoRelacionamento tipo;
  final String meuId;

  String get _titulo => tipo == TipoRelacionamento.seguidores
      ? 'Seguidores'
      : 'Seguindo';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            _Header(titulo: _titulo),
            const Divider(height: 1),
            Expanded(
              child: _Lista(
                scrollController: scrollController,
                meuId: meuId,
                tituloVazio: _titulo,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final total = context.select<ListaRelacionamentosProvider, int>(
      (p) => p.total,
    );
    final status = context.select<ListaRelacionamentosProvider,
        ListaRelacionamentosStatus>((p) => p.status);
    final mostrarTotal = status == ListaRelacionamentosStatus.success;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (mostrarTotal) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$total',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Lista extends StatefulWidget {
  const _Lista({
    required this.scrollController,
    required this.meuId,
    required this.tituloVazio,
  });

  final ScrollController scrollController;
  final String meuId;
  final String tituloVazio;

  @override
  State<_Lista> createState() => _ListaState();
}

class _ListaState extends State<_Lista> {
  static const double _thresholdCarregarMais = 300;

  late final ListaRelacionamentosProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ListaRelacionamentosProvider>();
    _provider.addListener(_onProviderChange);
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChange);
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final posicao = widget.scrollController.position;
    if (posicao.pixels >= posicao.maxScrollExtent - _thresholdCarregarMais) {
      _provider.carregarMais();
    }
  }

  void _onProviderChange() {
    final erro = _provider.ultimoErroAcao;
    if (erro != null && mounted) {
      _provider.limparUltimoErroAcao();
      AppSnackbar.showError(context, erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ListaRelacionamentosProvider>();

    switch (provider.status) {
      case ListaRelacionamentosStatus.idle:
      case ListaRelacionamentosStatus.loading:
        return _SkeletonLista(controller: widget.scrollController);
      case ListaRelacionamentosStatus.error:
        return _ErroInicial(
          mensagem: provider.errorMessage ?? 'Não foi possível carregar.',
          onTentarNovamente: provider.carregarInicial,
        );
      case ListaRelacionamentosStatus.success:
        if (provider.itens.isEmpty) {
          return _ListaVazia(titulo: widget.tituloVazio);
        }
        return ListView.builder(
          controller: widget.scrollController,
          itemCount: provider.itens.length + (provider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= provider.itens.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final usuario = provider.itens[index];
            final ehProprio = usuario.id == widget.meuId;
            return ItemRelacionamento(
              usuario: usuario,
              ehProprioViewer: ehProprio,
              emProcessamento: provider.emProcessamento(usuario.id),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(
                  '/perfil',
                  arguments: usuario.id,
                );
              },
              onSeguir: () => provider.seguir(usuario.id),
              onDeixarDeSeguir: () => provider.deixarDeSeguir(usuario.id),
            );
          },
        );
    }
  }
}

class _SkeletonLista extends StatelessWidget {
  const _SkeletonLista({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return ListView.builder(
      controller: controller,
      itemCount: 6,
      itemBuilder: (_, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 22, backgroundColor: colors.surfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 90,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ErroInicial extends StatelessWidget {
  const _ErroInicial({
    required this.mensagem,
    required this.onTentarNovamente,
  });

  final String mensagem;
  final Future<void> Function() onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(mensagem, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: onTentarNovamente,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _ListaVazia extends StatelessWidget {
  const _ListaVazia({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final mensagem = titulo == 'Seguidores'
        ? 'Ninguém está seguindo ainda.'
        : 'Ainda não está seguindo ninguém.';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: colors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
