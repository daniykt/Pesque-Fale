import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/data/avaliacoes_exceptions.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/data/avaliacoes_repository_mock.dart';
import 'package:pesque_fale_app/features/ponto_detalhe/domain/criar_editar_avaliacao_input.dart';

void main() {
  late AvaliacoesRepositoryMock repository;

  setUp(() {
    repository = AvaliacoesRepositoryMock();
  });

  group('AvaliacoesRepositoryMock - listar', () {
    test('retorna avaliacoes seed de um ponto ordenadas por mais recente', () async {
      final avaliacoes = await repository.listar('1');

      expect(avaliacoes, hasLength(2));
      expect(avaliacoes.first.id, 'av-1');
    });

    test('retorna vazio para ponto sem avaliacoes', () async {
      final avaliacoes = await repository.listar('ponto-sem-avaliacoes');

      expect(avaliacoes, isEmpty);
    });
  });

  group('AvaliacoesRepositoryMock - minhaAvaliacao', () {
    test('retorna null quando o usuario ainda nao avaliou', () async {
      final minha = await repository.minhaAvaliacao('1');

      expect(minha, isNull);
    });

    test('retorna a avaliacao apos criar', () async {
      await repository.criar(
        '1',
        const CriarEditarAvaliacaoInput(nota: 4.5, comentario: 'Muito bom'),
      );

      final minha = await repository.minhaAvaliacao('1');

      expect(minha, isNotNull);
      expect(minha!.nota, 4.5);
      expect(minha.comentario, 'Muito bom');
    });
  });

  group('AvaliacoesRepositoryMock - criar', () {
    test('cria avaliacao com sucesso', () async {
      final nova = await repository.criar(
        '2',
        const CriarEditarAvaliacaoInput(nota: 3.5),
      );

      expect(nova.nota, 3.5);
      expect(nova.pontoId, '2');
    });

    test('lanca JaAvaliouException ao criar duas vezes para o mesmo ponto', () async {
      await repository.criar('2', const CriarEditarAvaliacaoInput(nota: 3));

      expect(
        () => repository.criar('2', const CriarEditarAvaliacaoInput(nota: 4)),
        throwsA(isA<JaAvaliouException>()),
      );
    });
  });

  group('AvaliacoesRepositoryMock - editar', () {
    test('edita a avaliacao existente preservando criadoEm', () async {
      final criada = await repository.criar(
        '3',
        const CriarEditarAvaliacaoInput(nota: 2),
      );

      final editada = await repository.editar(
        '3',
        const CriarEditarAvaliacaoInput(nota: 5, comentario: 'Melhorei a nota'),
      );

      expect(editada.nota, 5);
      expect(editada.comentario, 'Melhorei a nota');
      expect(editada.criadoEm, criada.criadoEm);
    });

    test('lanca AvaliacaoNaoEncontradaException ao editar sem avaliar antes', () {
      expect(
        () => repository.editar(
          '4',
          const CriarEditarAvaliacaoInput(nota: 5),
        ),
        throwsA(isA<AvaliacaoNaoEncontradaException>()),
      );
    });
  });

  group('AvaliacoesRepositoryMock - deletar', () {
    test('deleta a avaliacao existente', () async {
      await repository.criar('5', const CriarEditarAvaliacaoInput(nota: 4));

      await repository.deletar('5');

      final minha = await repository.minhaAvaliacao('5');
      expect(minha, isNull);
    });

    test('lanca AvaliacaoNaoEncontradaException ao deletar sem avaliar antes', () {
      expect(
        () => repository.deletar('6'),
        throwsA(isA<AvaliacaoNaoEncontradaException>()),
      );
    });
  });
}
