import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../domain/ponto.dart';
import '../../providers/pesquisa_locais_provider.dart';
import 'ponto_details_sheet.dart';
import 'ponto_marker.dart';
import 'skeletons/mapa_skeleton.dart';

const _posicaoPadrao = LatLng(-15.7801, -47.9292);

class LocaisMapaView extends StatefulWidget {
  const LocaisMapaView({super.key});

  @override
  State<LocaisMapaView> createState() => _LocaisMapaViewState();
}

class _LocaisMapaViewState extends State<LocaisMapaView> {
  final MapController _mapController = MapController();
  String? _ultimoCentradoId;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final provider = context.watch<PesquisaLocaisProvider>();

    if (provider.status == PesquisaLocaisStatus.carregando &&
        provider.pontos.isEmpty) {
      return const MapaSkeleton();
    }

    final posicaoUsuario = provider.posicaoUsuario;
    final centro = posicaoUsuario != null
        ? LatLng(posicaoUsuario.latitude, posicaoUsuario.longitude)
        : _posicaoPadrao;

    final destacadoId = provider.pontoDestacadoId;
    if (destacadoId != null && destacadoId != _ultimoCentradoId) {
      Ponto? pontoDestacado;
      for (final p in provider.pontos) {
        if (p.id == destacadoId) {
          pontoDestacado = p;
          break;
        }
      }
      if (pontoDestacado != null) {
        _ultimoCentradoId = destacadoId;
        final ponto = pontoDestacado;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapController.move(
            LatLng(ponto.latitude, ponto.longitude),
            15,
          );
        });
      }
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: centro, initialZoom: 12),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.pesqueefale.app',
            ),
            if (posicaoUsuario != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(
                      posicaoUsuario.latitude,
                      posicaoUsuario.longitude,
                    ),
                    radius: provider.filtros.raioKm * 1000,
                    useRadiusInMeter: true,
                    color: colors.primary.withValues(alpha: 0.10),
                    borderColor: colors.primary.withValues(alpha: 0.3),
                    borderStrokeWidth: 1,
                  ),
                ],
              ),
            if (posicaoUsuario != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      posicaoUsuario.latitude,
                      posicaoUsuario.longitude,
                    ),
                    width: 12,
                    height: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            MarkerLayer(
              markers: provider.pontos.map((ponto) {
                return Marker(
                  point: LatLng(ponto.latitude, ponto.longitude),
                  width: 40,
                  height: 40,
                  child: PontoMarker(
                    tipo: ponto.tipo,
                    isDestacado: provider.pontoDestacadoId == ponto.id,
                    onTap: () {
                      provider.destacarPonto(ponto.id);
                      PontoDetailsSheet.show(context, ponto);
                    },
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
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.md,
          child: _ChipRaio(raioKm: provider.filtros.raioKm),
        ),
        Positioned(
          bottom: AppSpacing.md,
          right: AppSpacing.md,
          child: FloatingActionButton(
            heroTag: 'locais-mapa-minha-localizacao',
            onPressed: () async {
              if (posicaoUsuario != null) {
                _mapController.move(centro, 14);
                return;
              }
              await provider.alterarModo(ModoLocais.mapa);
              if (provider.localizacaoNegada && context.mounted) {
                AppSnackbar.showWarning(
                  context,
                  'Ative a localização para usar o mapa',
                );
              }
            },
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}

class _ChipRaio extends StatelessWidget {
  const _ChipRaio({required this.raioKm});

  final double raioKm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final provider = context.read<PesquisaLocaisProvider>();

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _abrirSeletorRaio(context, provider),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.social_distance, size: 16, color: colors.primary),
              const SizedBox(width: 4),
              Text('Raio: ${raioKm.toInt()} km'),
              const SizedBox(width: 4),
              Icon(Icons.tune, size: 16, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirSeletorRaio(
    BuildContext context,
    PesquisaLocaisProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          var raio = provider.filtros.raioKm;
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Raio de busca: ${raio.toInt()} km',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  value: raio,
                  min: 10,
                  max: 200,
                  divisions: 19,
                  label: '${raio.toInt()} km',
                  onChanged: (v) => setModalState(() => raio = v),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      provider.alterarRaio(raio);
                      Navigator.pop(context);
                    },
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
