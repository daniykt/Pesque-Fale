import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../clima/providers/clima_provider.dart';
import '../../domain/aba_feed.dart';
import '../../providers/feed_provider.dart';
import 'clima_card.dart';
import 'dica_do_dia_card.dart';

class DicasView extends StatefulWidget {
  const DicasView({super.key});

  @override
  State<DicasView> createState() => _DicasViewState();
}

class _DicasViewState extends State<DicasView> {
  late final FeedProvider _feed;
  bool _estavaAberta = false;

  @override
  void initState() {
    super.initState();
    _feed = context.read<FeedProvider>()..addListener(_onAbaMudou);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onAbaMudou();
    });
  }

  @override
  void dispose() {
    _feed.removeListener(_onAbaMudou);
    super.dispose();
  }

  void _onAbaMudou() {
    final aberta = _feed.abaAtiva == AbaFeed.dicas;
    if (aberta && !_estavaAberta) context.read<ClimaProvider>().abrir();
    _estavaAberta = aberta;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<ClimaProvider>().atualizar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          ClimaCard(),
          SizedBox(height: AppSpacing.md),
          DicaDoDiaCard(),
        ],
      ),
    );
  }
}
