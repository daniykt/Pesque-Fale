import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/utils/tipo_visuals.dart';
import '../data/pontos_repository.dart';
import '../domain/ponto.dart';
import '../providers/pesquisa_locais_provider.dart';
import 'widgets/busca_bar.dart';
import 'widgets/ponto_marker.dart';
import 'widgets/skeletons/mapa_skeleton.dart';

const _posicaoPadrao = LatLng(-15.7801, -47.9292);

class SeletorPontoPage extends StatelessWidget {
  const SeletorPontoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PesquisaLocaisProvider>(
      create: (ctx) =>
          PesquisaLocaisProvider(repository: ctx.read<PontosRepository>())
            ..inicializar(),
      child: const _SeletorPontoScaffold(),
    );
  }
}

class _SeletorPontoScaffold extends StatelessWidget {
  const _SeletorPontoScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar ponto de pesca')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: BuscaBar(
              hintText: 'Buscar ponto de pesca...',
              onChanged: (texto) =>
                  context.read<PesquisaLocaisProvider>().alterarBusca(texto),
            ),
          ),
          Expanded(
            child: _SeletorMapaView(
              onPontoSelecionado: (ponto) => Navigator.of(context).pop(ponto),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeletorMapaView extends StatefulWidget {
  const _SeletorMapaView({required this.onPontoSelecionado});

  final ValueChanged<Ponto> onPontoSelecionado;

  @override
  State<_SeletorMapaView> createState() => _SeletorMapaViewState();
}

class _SeletorMapaViewState extends State<_SeletorMapaView> {
  final MapController _mapController = MapController();
  Ponto? _pontoTocado;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PesquisaLocaisProvider>();

    if (provider.status == PesquisaLocaisStatus.carregando &&
        provider.pontos.isEmpty) {
      return const MapaSkeleton();
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _posicaoPadrao,
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.pesqueefale.app',
            ),
            MarkerLayer(
              markers: provider.pontos.map((ponto) {
                return Marker(
                  point: LatLng(ponto.latitude, ponto.longitude),
                  width: 40,
                  height: 40,
                  child: PontoMarker(
                    tipo: ponto.tipo,
                    isDestacado: _pontoTocado?.id == ponto.id,
                    onTap: () => setState(() => _pontoTocado = ponto),
                  ),
                );
              }).toList(),
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  '© OpenStreetMap contributors',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
        if (_pontoTocado != null)
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: _CardConfirmacao(
              ponto: _pontoTocado!,
              onSelecionar: () => widget.onPontoSelecionado(_pontoTocado!),
            ),
          ),
      ],
    );
  }
}

class _CardConfirmacao extends StatelessWidget {
  const _CardConfirmacao({required this.ponto, required this.onSelecionar});

  final Ponto ponto;
  final VoidCallback onSelecionar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Material(
      color: colors.surface,
      borderRadius: AppRadius.mdRadius,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              TipoVisuals.iconeDe(ponto.tipo),
              color: TipoVisuals.corDe(ponto.tipo),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ponto.nome,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${ponto.tipo.label} · ${ponto.cidade}-${ponto.estado}',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            ElevatedButton(
              onPressed: onSelecionar,
              child: const Text('Selecionar'),
            ),
          ],
        ),
      ),
    );
  }
}
