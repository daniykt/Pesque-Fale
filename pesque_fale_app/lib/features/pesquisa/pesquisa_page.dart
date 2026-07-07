import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../auth/data/token_storage.dart';
import 'package:latlong2/latlong.dart';

class PesquisaPage extends StatefulWidget {
  const PesquisaPage({super.key});

  @override
  State<PesquisaPage> createState() => _PesquisaPageState();
}

class _PesquisaPageState extends State<PesquisaPage> {
  final MapController _mapController = MapController();
  final TextEditingController _buscaController = TextEditingController();
  final TokenStorage _tokenStorage = TokenStorage();

  Position? _posicaoAtual;
  List<Map<String, dynamic>> _pontos = [];
  bool _carregando = false;
  bool _localizacaoNegada = false;
  double _raio = 50;

  @override
  void initState() {
    super.initState();
    _obterLocalizacao();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _obterLocalizacao() async {
    setState(() { _carregando = true; });

    try {
      bool servicoAtivo = await Geolocator.isLocationServiceEnabled();
      if (!servicoAtivo) {
        setState(() { _localizacaoNegada = true; _carregando = false; });
        return;
      }

      LocationPermission permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.deniedForever ||
          permissao == LocationPermission.denied) {
        setState(() { _localizacaoNegada = true; _carregando = false; });
        return;
      }

      final posicao = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() { _posicaoAtual = posicao; });
      await _buscarPontos();
    } catch (e) {
      setState(() { _carregando = false; });
    }
  }

  Future<void> _buscarPontos({String? busca}) async {
    setState(() { _carregando = true; });

    try {
      final token = await _tokenStorage.readToken();
      String url = '${AppConfig.apiBaseUrl}/pontos?porPagina=50';

      if (_posicaoAtual != null) {
        url += '&lat=${_posicaoAtual!.latitude}&lng=${_posicaoAtual!.longitude}&raio=$_raio';
      }
      if (busca != null && busca.isNotEmpty) {
        url += '&busca=${Uri.encodeComponent(busca)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>? ?? [];
        setState(() {
          _pontos = data.map((e) => e as Map<String, dynamic>).toList();
          _carregando = false;
        });

        if (_pontos.isNotEmpty && _posicaoAtual == null) {
          final primeiro = _pontos.first;
          _mapController.move(
            LatLng(
              (primeiro['latitude'] as num).toDouble(),
              (primeiro['longitude'] as num).toDouble(),
            ),
            12,
          );
        }
      } else {
        setState(() { _carregando = false; });
      }
    } catch (e) {
      setState(() { _carregando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final posicaoInicial = _posicaoAtual != null
        ? LatLng(_posicaoAtual!.latitude, _posicaoAtual!.longitude)
        : const LatLng(-15.7801, -47.9292);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: posicaoInicial,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pesqueefale.app',
              ),
              if (_posicaoAtual != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _posicaoAtual!.latitude,
                        _posicaoAtual!.longitude,
                      ),
                      width: 20,
                      height: 20,
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
                markers: _pontos.map((ponto) {
                  return Marker(
                    point: LatLng(
                      (ponto['latitude'] as num).toDouble(),
                      (ponto['longitude'] as num).toDouble(),
                    ),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _mostrarDetalhes(ponto),
                      child: Icon(
                        Icons.location_on,
                        color: colors.primary,
                        size: 40,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Barra de busca
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.sm,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(Icons.search),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: TextField(
                        controller: _buscaController,
                        decoration: const InputDecoration(
                          hintText: 'Buscar ponto de pesca...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (v) => _buscarPontos(busca: v),
                      ),
                    ),
                    if (_carregando)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.tune),
                        onPressed: _mostrarFiltros,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Lista de pontos próximos
          if (_pontos.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textSecondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        itemCount: _pontos.length,
                        itemBuilder: (context, index) {
                          final ponto = _pontos[index];
                          return _CardPonto(
                            ponto: ponto,
                            onTap: () {
                              _mapController.move(
                                LatLng(
                                  (ponto['latitude'] as num).toDouble(),
                                  (ponto['longitude'] as num).toDouble(),
                                ),
                                15,
                              );
                              _mostrarDetalhes(ponto);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Localização negada
          if (_localizacaoNegada)
            Positioned(
              bottom: 16,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: Card(
                color: Colors.orange.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off, color: Colors.orange),
                      const SizedBox(width: AppSpacing.xs),
                      const Expanded(
                        child: Text(
                          'Localização desativada. Busca sem proximidade.',
                        ),
                      ),
                      TextButton(
                        onPressed: _obterLocalizacao,
                        child: const Text('Ativar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_posicaoAtual != null) {
            _mapController.move(
              LatLng(_posicaoAtual!.latitude, _posicaoAtual!.longitude),
              14,
            );
          } else {
            _obterLocalizacao();
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void _mostrarDetalhes(Map<String, dynamic> ponto) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ponto['nome']?.toString() ?? '',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                Text('${ponto['cidade']}, ${ponto['estado']}'),
                if (ponto['distanciaKm'] != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text('• ${ponto['distanciaKm']} km'),
                ],
              ],
            ),
            if (ponto['descricao'] != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(ponto['descricao'].toString()),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${ponto['avgNota']} (${ponto['totalAvaliacoes']} avaliações)',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Raio de busca: ${_raio.toInt()} km',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: _raio,
                min: 10,
                max: 200,
                divisions: 19,
                label: '${_raio.toInt()} km',
                onChanged: (v) => setModalState(() => _raio = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _buscarPontos(busca: _buscaController.text);
                  },
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardPonto extends StatelessWidget {
  const _CardPonto({required this.ponto, required this.onTap});

  final Map<String, dynamic> ponto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(
          right: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ponto['nome']?.toString() ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${ponto['cidade']}, ${ponto['estado']}',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (ponto['distanciaKm'] != null)
              Text(
                '${ponto['distanciaKm']} km',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            Row(
              children: [
                const Icon(Icons.star, size: 12, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  '${ponto['avgNota']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}