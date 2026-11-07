import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_exceptions.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_repository_mock.dart';
import 'package:pesque_fale_app/features/feed/domain/dados_evento.dart';

void main() {
  final agora = DateTime(2026, 11, 7, 10);

  EventosRepositoryMock novoRepo() =>
      EventosRepositoryMock(agora: () => agora, atraso: Duration.zero);

  DadosEvento dados({
    String titulo = 'Pescaria no lago',
    DateTime? inicio,
    DateTime? fim,
  }) => DadosEvento(
    titulo: titulo,
    dataInicio: inicio ?? agora.add(const Duration(days: 1)),
    dataFim: fim,
  );

  test(
    'criar adiciona o evento com o usuário do mock como organizador',
    () async {
      final repo = novoRepo();

      final criado = await repo.criar(dados());
      final lista = await repo.listar(limite: 50);

      expect(criado.organizadorId, 'mock-id');
      expect(lista.map((e) => e.id), contains(criado.id));
      expect((await repo.buscarPorId(criado.id)).titulo, 'Pescaria no lago');
    },
  );

  test('editar troca os dados e mantém organizador e criação', () async {
    final repo = novoRepo();
    final criado = await repo.criar(dados());

    final editado = await repo.editar(criado.id, dados(titulo: 'Outro título'));

    expect(editado.titulo, 'Outro título');
    expect(editado.organizadorId, criado.organizadorId);
    expect(editado.criadoEm, criado.criadoEm);
    expect((await repo.buscarPorId(criado.id)).titulo, 'Outro título');
  });

  test('excluir tira da lista e depois o evento não é encontrado', () async {
    final repo = novoRepo();
    final criado = await repo.criar(dados());

    await repo.excluir(criado.id);

    expect(
      (await repo.listar(limite: 50)).map((e) => e.id),
      isNot(contains(criado.id)),
    );
    await expectLater(
      repo.buscarPorId(criado.id),
      throwsA(isA<EventoNaoEncontradoException>()),
    );
    await expectLater(
      repo.excluir(criado.id),
      throwsA(isA<EventoNaoEncontradoException>()),
    );
    await expectLater(
      repo.editar(criado.id, dados()),
      throwsA(isA<EventoNaoEncontradoException>()),
    );
  });

  test('futuros inclui os em andamento e vem do mais próximo', () async {
    final repo = novoRepo();
    final emAndamento = await repo.criar(
      dados(
        inicio: agora.subtract(const Duration(hours: 2)),
        fim: agora.add(const Duration(hours: 2)),
      ),
    );
    final encerrado = await repo.criar(
      dados(
        inicio: agora.subtract(const Duration(days: 2)),
        fim: agora.subtract(const Duration(days: 1)),
      ),
    );

    final lista = await repo.listar(limite: 50);

    expect(lista.first.id, emAndamento.id);
    expect(lista.map((e) => e.id), isNot(contains(encerrado.id)));
    for (var i = 1; i < lista.length; i++) {
      expect(lista[i].dataInicio.isBefore(lista[i - 1].dataInicio), isFalse);
    }
  });

  test('sem futuros, lista todos do mais recente para o mais antigo', () async {
    final repo = novoRepo();
    final encerrado = await repo.criar(
      dados(inicio: agora.subtract(const Duration(days: 2))),
    );

    final lista = await repo.listar(futuros: false, limite: 50);

    expect(lista.map((e) => e.id), contains(encerrado.id));
    expect(lista.last.id, encerrado.id);
  });

  test('recusa fim antes do início, como a API', () async {
    final repo = novoRepo();
    final inicio = agora.add(const Duration(days: 1));

    await expectLater(
      repo.criar(
        dados(inicio: inicio, fim: inicio.subtract(const Duration(hours: 1))),
      ),
      throwsA(
        isA<EventoValidacaoException>().having(
          (e) => e.errosPorCampo.keys,
          'campos',
          ['dataFim'],
        ),
      ),
    );
  });

  test('recusa título curto, como a API', () async {
    final repo = novoRepo();

    await expectLater(
      repo.criar(dados(titulo: ' a ')),
      throwsA(isA<EventoValidacaoException>()),
    );
  });

  test('cada instância tem a própria lista', () async {
    final primeiro = novoRepo();
    final segundo = novoRepo();
    final criado = await primeiro.criar(dados());

    expect(
      (await segundo.listar(limite: 50)).map((e) => e.id),
      isNot(contains(criado.id)),
    );
  });
}
