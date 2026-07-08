import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_exceptions.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_repository.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/filtros_locais.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/ponto.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/tipo_ponto.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/data/avaliacoes_repository.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/domain/avaliacao.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/domain/criar_editar_avaliacao_input.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/providers/ponto_detalhe_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) async => throw UnimplementedError();

  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async {
    return const AuthResult(
      accessToken: 'token',
      usuario: Usuario(
        id: 'u1',
        nome: 'Ana',
        email: 'ana@teste.com',
        onboardingConcluido: true,
      ),
    );
  }

  @override
  Future<void> logout() async {}
}

Ponto _ponto({String id = 'p1', int totalAvaliacoes = 3}) => Ponto(
  id: id,
  nome: 'Rio das Pratas',
  latitude: -21.6,
  longitude: -48.3,
  cidade: 'Matão',
  estado: 'SP',
  tipo: TipoPonto.rio,
  totalAvaliacoes: totalAvaliacoes,
  avgNota: 4.5,
  criadoPor: 'u1',
);

Avaliacao _avaliacao({
  String id = 'a1',
  String usuarioId = 'u2',
  double nota = 4,
}) => Avaliacao(
  id: id,
  usuarioId: usuarioId,
  usuarioNome: 'Fulano',
  usuarioUsername: 'fulano',
  pontoId: 'p1',
  nota: nota,
  criadoEm: DateTime(2026, 1, 1),
  atualizadoEm: DateTime(2026, 1, 1),
);

class _FakePontosRepository implements PontosRepository {
  _FakePontosRepository({this.falhar = false});

  final bool falhar;
  int chamadasBuscarPorId = 0;

  @override
  Future<List<Ponto>> buscar({
    required FiltrosLocais filtros,
    double? lat,
    double? lng,
    bool incluirDistancia = false,
  }) async => throw UnimplementedError();

  @override
  Future<Ponto> buscarPorId(String id) async {
    chamadasBuscarPorId++;
    if (falhar) throw const PontoNaoEncontradoException();
    return _ponto(id: id);
  }
}

class _FakeAvaliacoesRepository implements AvaliacoesRepository {
  _FakeAvaliacoesRepository({
    this.lista = const [],
    this.minha,
  });

  List<Avaliacao> lista;
  Avaliacao? minha;
  int chamadasMinhaAvaliacao = 0;

  @override
  Future<List<Avaliacao>> listar(
    String pontoId, {
    int pagina = 1,
    int porPagina = 20,
  }) async => lista;

  @override
  Future<Avaliacao?> minhaAvaliacao(String pontoId) async {
    chamadasMinhaAvaliacao++;
    return minha;
  }

  @override
  Future<Avaliacao> criar(
    String pontoId,
    CriarEditarAvaliacaoInput input,
  ) async => throw UnimplementedError();

  @override
  Future<Avaliacao> editar(
    String pontoId,
    CriarEditarAvaliacaoInput input,
  ) async => throw UnimplementedError();

  @override
  Future<void> deletar(String pontoId) async {}
}

void main() {
  group('PontoDetalheProvider - carregar', () {
    test(
      'carrega ponto, avaliacoes e minha avaliacao em paralelo quando logado',
      () async {
        final authRepository = _FakeAuthRepository();
        final authProvider = AuthProvider(repository: authRepository);
        await authProvider.login(email: 'ana@teste.com', senha: '123456');

        final pontosRepository = _FakePontosRepository();
        final avaliacoesRepository = _FakeAvaliacoesRepository(
          lista: [_avaliacao()],
          minha: _avaliacao(id: 'minha', usuarioId: 'u1'),
        );

        final provider = PontoDetalheProvider(
          pontosRepository: pontosRepository,
          avaliacoesRepository: avaliacoesRepository,
          authProvider: authProvider,
        );

        await provider.carregar('p1');

        expect(provider.status, PontoDetalheStatus.sucesso);
        expect(provider.ponto?.id, 'p1');
        expect(provider.totalAvaliacoes, 3);
        expect(provider.primeirasAvaliacoes, hasLength(1));
        expect(provider.minhaAvaliacao?.id, 'minha');
        expect(avaliacoesRepository.chamadasMinhaAvaliacao, 1);
      },
    );

    test('nao busca minha avaliacao quando deslogado', () async {
      final authProvider = AuthProvider(repository: _FakeAuthRepository());

      final pontosRepository = _FakePontosRepository();
      final avaliacoesRepository = _FakeAvaliacoesRepository();

      final provider = PontoDetalheProvider(
        pontosRepository: pontosRepository,
        avaliacoesRepository: avaliacoesRepository,
        authProvider: authProvider,
      );

      await provider.carregar('p1');

      expect(provider.status, PontoDetalheStatus.sucesso);
      expect(provider.minhaAvaliacao, isNull);
      expect(avaliacoesRepository.chamadasMinhaAvaliacao, 0);
    });

    test('status erro quando buscarPorId falha', () async {
      final authProvider = AuthProvider(repository: _FakeAuthRepository());
      final pontosRepository = _FakePontosRepository(falhar: true);
      final avaliacoesRepository = _FakeAvaliacoesRepository();

      final provider = PontoDetalheProvider(
        pontosRepository: pontosRepository,
        avaliacoesRepository: avaliacoesRepository,
        authProvider: authProvider,
      );

      await provider.carregar('p1');

      expect(provider.status, PontoDetalheStatus.erro);
      expect(provider.mensagemErro, isNotNull);
    });
  });

  group('PontoDetalheProvider - aplicarNovaAvaliacao', () {
    test('incrementa totalAvaliacoes e insere no topo quando e nova', () async {
      final authProvider = AuthProvider(repository: _FakeAuthRepository());
      await authProvider.login(email: 'ana@teste.com', senha: '123456');
      final pontosRepository = _FakePontosRepository();
      final avaliacoesRepository = _FakeAvaliacoesRepository(
        lista: [_avaliacao(id: 'outra', usuarioId: 'u3')],
      );

      final provider = PontoDetalheProvider(
        pontosRepository: pontosRepository,
        avaliacoesRepository: avaliacoesRepository,
        authProvider: authProvider,
      );
      await provider.carregar('p1');

      final totalAntes = provider.totalAvaliacoes;
      provider.aplicarNovaAvaliacao(
        _avaliacao(id: 'minha', usuarioId: 'u1', nota: 5),
      );

      expect(provider.minhaAvaliacao?.id, 'minha');
      expect(provider.totalAvaliacoes, totalAntes + 1);
      expect(provider.primeirasAvaliacoes.first.id, 'minha');
    });

    test('nao incrementa total quando e edicao da mesma avaliacao', () async {
      final authProvider = AuthProvider(repository: _FakeAuthRepository());
      await authProvider.login(email: 'ana@teste.com', senha: '123456');
      final pontosRepository = _FakePontosRepository();
      final avaliacoesRepository = _FakeAvaliacoesRepository(
        lista: [_avaliacao(id: 'minha', usuarioId: 'u1', nota: 3)],
        minha: _avaliacao(id: 'minha', usuarioId: 'u1', nota: 3),
      );

      final provider = PontoDetalheProvider(
        pontosRepository: pontosRepository,
        avaliacoesRepository: avaliacoesRepository,
        authProvider: authProvider,
      );
      await provider.carregar('p1');

      final totalAntes = provider.totalAvaliacoes;
      provider.aplicarNovaAvaliacao(
        _avaliacao(id: 'minha', usuarioId: 'u1', nota: 5),
      );

      expect(provider.totalAvaliacoes, totalAntes);
      expect(provider.minhaAvaliacao?.nota, 5);
    });
  });

  group('PontoDetalheProvider - removerMinhaAvaliacao', () {
    test('remove a minha avaliacao e decrementa o total', () async {
      final authProvider = AuthProvider(repository: _FakeAuthRepository());
      await authProvider.login(email: 'ana@teste.com', senha: '123456');
      final pontosRepository = _FakePontosRepository();
      final avaliacoesRepository = _FakeAvaliacoesRepository(
        lista: [_avaliacao(id: 'minha', usuarioId: 'u1')],
        minha: _avaliacao(id: 'minha', usuarioId: 'u1'),
      );

      final provider = PontoDetalheProvider(
        pontosRepository: pontosRepository,
        avaliacoesRepository: avaliacoesRepository,
        authProvider: authProvider,
      );
      await provider.carregar('p1');

      final totalAntes = provider.totalAvaliacoes;
      provider.removerMinhaAvaliacao();

      expect(provider.minhaAvaliacao, isNull);
      expect(provider.totalAvaliacoes, totalAntes - 1);
      expect(
        provider.primeirasAvaliacoes.any((a) => a.id == 'minha'),
        isFalse,
      );
    });
  });
}
