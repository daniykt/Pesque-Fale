import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/tipo_visuals.dart';
import '../../../pesquisa/data/pontos_exceptions.dart';
import '../../../pesquisa/data/pontos_repository.dart';
import '../../../pesquisa/domain/filtros_locais.dart';
import '../../../pesquisa/domain/ponto.dart';
import '../../../pesquisa/presentation/widgets/busca_bar.dart';

class SelecaoPontoBottomSheet {
  SelecaoPontoBottomSheet._();

  static Future<Ponto?> show(BuildContext context) {
    final repository = context.read<PontosRepository>();

    return showModalBottomSheet<Ponto>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => _ConteudoSheet(
            repository: repository,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }
}

class _ConteudoSheet extends StatefulWidget {
  const _ConteudoSheet({
    required this.repository,
    required this.scrollController,
  });

  final PontosRepository repository;
  final ScrollController scrollController;

  @override
  State<_ConteudoSheet> createState() => _ConteudoSheetState();
}

class _ConteudoSheetState extends State<_ConteudoSheet> {
  List<Ponto> _todos = [];
  String _busca = '';
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      // Filtros vazios: a API devolve todos os pontos cadastrados.
      final pontos = await widget.repository.buscar(
        filtros: const FiltrosLocais(),
      );
      if (!mounted) return;
      setState(() {
        _todos = pontos;
        _carregando = false;
      });
    } on PontosException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.message;
        _carregando = false;
      });
    }
  }

  List<Ponto> get _filtrados {
    final termo = _busca.trim().toLowerCase();
    if (termo.isEmpty) return _todos;
    return _todos.where((p) => p.nome.toLowerCase().contains(termo)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(
            top: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Text(
          'Escolher local da pescaria',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: BuscaBar(
            hintText: 'Buscar por nome...',
            onChanged: (texto) => setState(() => _busca = texto),
          ),
        ),
        Expanded(child: _buildConteudo(colors)),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.border)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            'Não encontrou o seu local? Fale conosco: contato@pesquefale.app',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildConteudo(AppColors colors) {
    if (_carregando && _todos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return _Mensagem(
        texto: _erro!,
        colors: colors,
        acao: ElevatedButton(
          onPressed: _carregar,
          child: const Text('Tentar novamente'),
        ),
      );
    }

    if (_todos.isEmpty) {
      return _Mensagem(
        texto: 'Nenhum ponto cadastrado ainda. Fale com a equipe pra sugerir.',
        colors: colors,
      );
    }

    final filtrados = _filtrados;
    if (filtrados.isEmpty) {
      return _Mensagem(
        texto: 'Nenhum ponto encontrado para "${_busca.trim()}"',
        colors: colors,
      );
    }

    return ListView.separated(
      controller: widget.scrollController,
      itemCount: filtrados.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
      itemBuilder: (context, index) {
        final p = filtrados[index];
        return ListTile(
          leading: Icon(
            TipoVisuals.iconeDe(p.tipo),
            color: TipoVisuals.corDe(p.tipo),
          ),
          title: Text(p.nome),
          subtitle: Text('${p.tipo.label} · ${p.cidade}-${p.estado}'),
          onTap: () => Navigator.pop(context, p),
        );
      },
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({required this.texto, required this.colors, this.acao});

  final String texto;
  final AppColors colors;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary),
            ),
            if (acao != null) ...[const SizedBox(height: AppSpacing.md), acao!],
          ],
        ),
      ),
    );
  }
}
