import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/data/avaliacoes_exceptions.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/data/avaliacoes_repository.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/domain/avaliacao.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/domain/criar_editar_avaliacao_input.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/providers/avaliar_provider.dart';

Avaliacao _avaliacao({String id = 'a1', double nota = 4, String? comentario}) =>
    Avaliacao(
      id: id,
      usuarioId: 'u1',
      usuarioNome: 'Ana',
      usuarioUsername: 'ana',
      pontoId: 'p1',
      nota: nota,
      comentario: comentario,
      criadoEm: DateTime(2026, 1, 1),
      atualizadoEm: DateTime(2026, 1, 1),
    );

class _FakeAvaliacoesRepository implements AvaliacoesRepository {
  _FakeAvaliacoesRepository({this.falhar = false});

  final bool falhar;
  CriarEditarAvaliacaoInput? ultimoInputCriado;
  CriarEditarAvaliacaoInput? ultimoInputEditado;
  bool deletarChamado = false;

  @override
  Future<List<Avaliacao>> listar(
    String pontoId, {
    int pagina = 1,
    int porPagina = 20,
  }) async => throw UnimplementedError();

  @override
  Future<Avaliacao?> minhaAvaliacao(String pontoId) async =>
      throw UnimplementedError();

  @override
  Future<Avaliacao> criar(
    String pontoId,
    CriarEditarAvaliacaoInput input,
  ) async {
    ultimoInputCriado = input;
    if (falhar) throw const InternalServerException();
    return _avaliacao(nota: input.nota, comentario: input.comentario);
  }

  @override
  Future<Avaliacao> editar(
    String pontoId,
    CriarEditarAvaliacaoInput input,
  ) async {
    ultimoInputEditado = input;
    if (falhar) throw const JaAvaliouException();
    return _avaliacao(nota: input.nota, comentario: input.comentario);
  }

  @override
  Future<void> deletar(String pontoId) async {
    deletarChamado = true;
    if (falhar) throw const AvaliacaoNaoEncontradaException();
  }
}

void main() {
  group('AvaliarProvider - validacao de nota', () {
    test('podeSalvar false quando nota nao foi escolhida', () {
      final provider = AvaliarProvider(repository: _FakeAvaliacoesRepository());
      provider.inicializar();

      expect(provider.podeSalvar, isFalse);
    });

    test('podeSalvar true apos alterarNota', () {
      final provider = AvaliarProvider(repository: _FakeAvaliacoesRepository());
      provider.inicializar();

      provider.alterarNota(3.5);

      expect(provider.podeSalvar, isTrue);
      expect(provider.nota, 3.5);
    });

    test('alterarNota faz clamp entre 1.0 e 5.0', () {
      final provider = AvaliarProvider(repository: _FakeAvaliacoesRepository());
      provider.inicializar();

      provider.alterarNota(0.5);
      expect(provider.nota, 1.0);

      provider.alterarNota(7.0);
      expect(provider.nota, 5.0);
    });

    test('alterarComentario trunca em 500 caracteres', () {
      final provider = AvaliarProvider(repository: _FakeAvaliacoesRepository());
      provider.inicializar();

      provider.alterarComentario('a' * 600);

      expect(provider.comentario, hasLength(500));
    });
  });

  group('AvaliarProvider - inicializar', () {
    test('ehEdicao false e nota 0 quando nao ha avaliacao existente', () {
      final provider = AvaliarProvider(repository: _FakeAvaliacoesRepository());
      provider.inicializar();

      expect(provider.ehEdicao, isFalse);
      expect(provider.nota, 0);
    });

    test('ehEdicao true e pre-preenche quando ha avaliacao existente', () {
      final provider = AvaliarProvider(repository: _FakeAvaliacoesRepository());
      provider.inicializar(
        existente: _avaliacao(nota: 4.5, comentario: 'Muito bom'),
      );

      expect(provider.ehEdicao, isTrue);
      expect(provider.nota, 4.5);
      expect(provider.comentario, 'Muito bom');
    });
  });

  group('AvaliarProvider - salvar', () {
    test('chama criar quando nao e edicao', () async {
      final repository = _FakeAvaliacoesRepository();
      final provider = AvaliarProvider(repository: repository);
      provider.inicializar();
      provider.alterarNota(4);

      final resultado = await provider.salvar('p1');

      expect(resultado, isNotNull);
      expect(repository.ultimoInputCriado?.nota, 4);
      expect(repository.ultimoInputEditado, isNull);
      expect(provider.status, AvaliarStatus.sucesso);
    });

    test('chama editar quando e edicao', () async {
      final repository = _FakeAvaliacoesRepository();
      final provider = AvaliarProvider(repository: repository);
      provider.inicializar(existente: _avaliacao(nota: 2));
      provider.alterarNota(5);

      final resultado = await provider.salvar('p1');

      expect(resultado, isNotNull);
      expect(repository.ultimoInputEditado?.nota, 5);
      expect(repository.ultimoInputCriado, isNull);
    });

    test(
      'retorna null e nao chama repositorio quando nota nao escolhida',
      () async {
        final repository = _FakeAvaliacoesRepository();
        final provider = AvaliarProvider(repository: repository);
        provider.inicializar();

        final resultado = await provider.salvar('p1');

        expect(resultado, isNull);
        expect(repository.ultimoInputCriado, isNull);
      },
    );

    test(
      'deixa mensagemErro e status erro quando o repositorio falha',
      () async {
        final repository = _FakeAvaliacoesRepository(falhar: true);
        final provider = AvaliarProvider(repository: repository);
        provider.inicializar();
        provider.alterarNota(3);

        final resultado = await provider.salvar('p1');

        expect(resultado, isNull);
        expect(provider.status, AvaliarStatus.erro);
        expect(provider.mensagemErro, isNotNull);
      },
    );
  });

  group('AvaliarProvider - deletar', () {
    test('retorna false quando nao e edicao', () async {
      final repository = _FakeAvaliacoesRepository();
      final provider = AvaliarProvider(repository: repository);
      provider.inicializar();

      final ok = await provider.deletar('p1');

      expect(ok, isFalse);
      expect(repository.deletarChamado, isFalse);
    });

    test('deleta com sucesso quando e edicao', () async {
      final repository = _FakeAvaliacoesRepository();
      final provider = AvaliarProvider(repository: repository);
      provider.inicializar(existente: _avaliacao());

      final ok = await provider.deletar('p1');

      expect(ok, isTrue);
      expect(repository.deletarChamado, isTrue);
      expect(provider.status, AvaliarStatus.sucesso);
    });

    test('retorna false e mensagemErro quando o repositorio falha', () async {
      final repository = _FakeAvaliacoesRepository(falhar: true);
      final provider = AvaliarProvider(repository: repository);
      provider.inicializar(existente: _avaliacao());

      final ok = await provider.deletar('p1');

      expect(ok, isFalse);
      expect(provider.status, AvaliarStatus.erro);
      expect(provider.mensagemErro, isNotNull);
    });
  });
}
