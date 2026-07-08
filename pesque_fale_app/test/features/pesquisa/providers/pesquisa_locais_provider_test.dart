import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_exceptions.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_repository.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/avaliacao_min_filtro.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/filtros_locais.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/ponto.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/tipo_ponto.dart';
import 'package:pesque_fale_app/features/pesquisa/providers/pesquisa_locais_provider.dart';

class _FakePontosRepository implements PontosRepository {
  _FakePontosRepository({this.resultado = const [], this.erro});

  List<Ponto> resultado;
  PontosException? erro;
  int chamadas = 0;
  FiltrosLocais? ultimoFiltros;
  double? ultimoLat;
  double? ultimoLng;
  bool? ultimoIncluirDistancia;

  @override
  Future<List<Ponto>> buscar({
    required FiltrosLocais filtros,
    double? lat,
    double? lng,
    bool incluirDistancia = false,
  }) async {
    chamadas++;
    ultimoFiltros = filtros;
    ultimoLat = lat;
    ultimoLng = lng;
    ultimoIncluirDistancia = incluirDistancia;
    if (erro != null) throw erro!;
    return resultado;
  }

  @override
  Future<Ponto> buscarPorId(String id) async => throw UnimplementedError();
}

Ponto _ponto(String id) => Ponto(
  id: id,
  nome: 'Ponto $id',
  latitude: -21.6,
  longitude: -48.3,
  cidade: 'São Carlos',
  estado: 'SP',
  tipo: TipoPonto.rio,
  criadoPor: 'u1',
);

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  _FakeGeolocatorPlatform({
    this.servicoAtivo = true,
    this.permissaoInicial = LocationPermission.denied,
    this.permissaoAposRequest = LocationPermission.whileInUse,
    this.posicao,
  });

  final bool servicoAtivo;
  final LocationPermission permissaoInicial;
  final LocationPermission permissaoAposRequest;
  final Position? posicao;

  @override
  Future<bool> isLocationServiceEnabled() async => servicoAtivo;

  @override
  Future<LocationPermission> checkPermission() async => permissaoInicial;

  @override
  Future<LocationPermission> requestPermission() async => permissaoAposRequest;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    if (posicao == null) throw Exception('sem posicao configurada no fake');
    return posicao!;
  }
}

Position _posicaoMock() => Position(
  latitude: -21.6082,
  longitude: -48.3658,
  timestamp: DateTime(2026, 1, 1),
  accuracy: 1,
  altitude: 0,
  altitudeAccuracy: 1,
  heading: 0,
  headingAccuracy: 1,
  speed: 0,
  speedAccuracy: 1,
);

void main() {
  setUp(() {
    GeolocatorPlatform.instance = _FakeGeolocatorPlatform(
      posicao: _posicaoMock(),
    );
  });

  test('inicializar busca pontos sem geolocalizacao', () async {
    final repository = _FakePontosRepository(resultado: [_ponto('1')]);
    final provider = PesquisaLocaisProvider(repository: repository);

    await provider.inicializar();

    expect(provider.status, PesquisaLocaisStatus.sucesso);
    expect(repository.chamadas, 1);
    expect(repository.ultimoLat, isNull);
    expect(repository.ultimoIncluirDistancia, isFalse);
  });

  test('vazio quando resultado da busca e vazio', () async {
    final repository = _FakePontosRepository(resultado: const []);
    final provider = PesquisaLocaisProvider(repository: repository);

    await provider.inicializar();

    expect(provider.status, PesquisaLocaisStatus.vazio);
  });

  test('erro quando o repositorio lanca excecao', () async {
    final repository = _FakePontosRepository(
      erro: const InternalServerException(),
    );
    final provider = PesquisaLocaisProvider(repository: repository);

    await provider.inicializar();

    expect(provider.status, PesquisaLocaisStatus.erro);
    expect(provider.mensagemErro, isNotNull);
  });

  test('debounce: alterarBusca so dispara uma requisicao apos pausa', () async {
    final repository = _FakePontosRepository(resultado: [_ponto('1')]);
    final provider = PesquisaLocaisProvider(repository: repository);

    provider.alterarBusca('r');
    provider.alterarBusca('ri');
    provider.alterarBusca('rio');

    await Future.delayed(const Duration(milliseconds: 600));

    expect(repository.chamadas, 1);
    expect(repository.ultimoFiltros?.busca, 'rio');
  });

  test('alterarTipo dispara busca imediatamente', () async {
    final repository = _FakePontosRepository(resultado: [_ponto('1')]);
    final provider = PesquisaLocaisProvider(repository: repository);

    provider.alterarTipo(TipoPonto.rio);
    await Future.delayed(const Duration(milliseconds: 50));

    expect(repository.ultimoFiltros?.tipo, TipoPonto.rio);
  });

  test('alterarAvaliacaoMin dispara busca imediatamente', () async {
    final repository = _FakePontosRepository(resultado: [_ponto('1')]);
    final provider = PesquisaLocaisProvider(repository: repository);

    provider.alterarAvaliacaoMin(AvaliacaoMinFiltro.quatro);
    await Future.delayed(const Duration(milliseconds: 50));

    expect(repository.ultimoFiltros?.avaliacaoMin, AvaliacaoMinFiltro.quatro);
  });

  test(
    'alterarModo(mapa) obtem geolocalizacao e busca com incluirDistancia',
    () async {
      final repository = _FakePontosRepository(resultado: [_ponto('1')]);
      final provider = PesquisaLocaisProvider(repository: repository);

      await provider.alterarModo(ModoLocais.mapa);

      expect(provider.modo, ModoLocais.mapa);
      expect(provider.localizacaoNegada, isFalse);
      expect(provider.posicaoUsuario, isNotNull);
      expect(repository.ultimoIncluirDistancia, isTrue);
      expect(repository.ultimoLat, -21.6082);
    },
  );

  test(
    'alterarModo(mapa) com permissao negada mantem modo lista e sinaliza',
    () async {
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform(
        permissaoInicial: LocationPermission.denied,
        permissaoAposRequest: LocationPermission.denied,
      );
      final repository = _FakePontosRepository(resultado: [_ponto('1')]);
      final provider = PesquisaLocaisProvider(repository: repository);

      await provider.alterarModo(ModoLocais.mapa);

      expect(provider.modo, ModoLocais.lista);
      expect(provider.localizacaoNegada, isTrue);
      expect(provider.posicaoUsuario, isNull);
    },
  );

  test(
    'alterarModo(mapa) com servico de localizacao desativado mantem modo lista',
    () async {
      GeolocatorPlatform.instance = _FakeGeolocatorPlatform(
        servicoAtivo: false,
      );
      final repository = _FakePontosRepository(resultado: [_ponto('1')]);
      final provider = PesquisaLocaisProvider(repository: repository);

      await provider.alterarModo(ModoLocais.mapa);

      expect(provider.modo, ModoLocais.lista);
      expect(provider.localizacaoNegada, isTrue);
      expect(provider.posicaoUsuario, isNull);
    },
  );

  test('destacarPonto atualiza o id destacado', () async {
    final repository = _FakePontosRepository(resultado: [_ponto('1')]);
    final provider = PesquisaLocaisProvider(repository: repository);

    provider.destacarPonto('1');
    expect(provider.pontoDestacadoId, '1');

    provider.destacarPonto(null);
    expect(provider.pontoDestacadoId, isNull);
  });
}
