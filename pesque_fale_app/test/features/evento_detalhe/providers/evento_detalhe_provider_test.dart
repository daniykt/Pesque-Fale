import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/evento_detalhe/providers/evento_detalhe_provider.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_exceptions.dart';

import '../fakes.dart';

void main() {
  group('carregar', () {
    test('com o evento do card, mostra na hora e atualiza com a API', () async {
      final repo = FakeEventosDetalheRepository(
        atual: eventoDeTeste(titulo: 'Título atualizado'),
      );
      final provider = EventoDetalheProvider(
        repository: repo,
        eventoInicial: eventoDeTeste(),
      );
      expect(provider.status, StatusEventoDetalhe.carregado);
      expect(provider.evento?.titulo, 'Torneio do Lago Azul');

      await provider.carregar();

      expect(repo.buscas, 1);
      expect(provider.evento?.titulo, 'Título atualizado');
    });

    test('só com o id, começa carregando e depois mostra', () async {
      final repo = FakeEventosDetalheRepository(atual: eventoDeTeste());
      final provider = EventoDetalheProvider(
        repository: repo,
        eventoId: 'ev-1',
      );
      expect(provider.status, StatusEventoDetalhe.carregando);

      await provider.carregar();

      expect(provider.status, StatusEventoDetalhe.carregado);
      expect(provider.evento?.id, 'ev-1');
    });

    test('404 vira "não encontrado", mesmo com o evento do card', () async {
      final repo = FakeEventosDetalheRepository()
        ..erroBuscar = const EventoNaoEncontradoException();
      final provider = EventoDetalheProvider(
        repository: repo,
        eventoInicial: eventoDeTeste(),
      );

      await provider.carregar();

      expect(provider.status, StatusEventoDetalhe.naoEncontrado);
      expect(provider.evento, isNull);
    });

    test('sem rede e sem evento, mostra o erro', () async {
      final repo = FakeEventosDetalheRepository()
        ..erroBuscar = const EventosRedeException();
      final provider = EventoDetalheProvider(
        repository: repo,
        eventoId: 'ev-1',
      );

      await provider.carregar();

      expect(provider.status, StatusEventoDetalhe.erro);
      expect(provider.mensagemErro, 'Sem conexão com o servidor.');
    });

    test('sem rede, mas com o evento do card, continua mostrando', () async {
      final repo = FakeEventosDetalheRepository()
        ..erroBuscar = const EventosRedeException();
      final provider = EventoDetalheProvider(
        repository: repo,
        eventoInicial: eventoDeTeste(),
      );

      await provider.carregar();

      expect(provider.status, StatusEventoDetalhe.carregado);
      expect(provider.evento?.titulo, 'Torneio do Lago Azul');
    });

    test('tentar de novo depois do erro carrega', () async {
      final repo = FakeEventosDetalheRepository(atual: eventoDeTeste())
        ..erroBuscar = const EventosRedeException();
      final provider = EventoDetalheProvider(
        repository: repo,
        eventoId: 'ev-1',
      );
      await provider.carregar();

      repo.erroBuscar = null;
      await provider.carregar();

      expect(provider.status, StatusEventoDetalhe.carregado);
      expect(provider.mensagemErro, isNull);
    });
  });

  test('só o organizador é reconhecido', () {
    final provider = EventoDetalheProvider(
      repository: FakeEventosDetalheRepository(),
      eventoInicial: eventoDeTeste(organizadorId: 'organizador'),
    );

    expect(provider.ehOrganizador('organizador'), isTrue);
    expect(provider.ehOrganizador('outra-pessoa'), isFalse);
    expect(provider.ehOrganizador(null), isFalse);
  });

  test('atualizar troca o evento mostrado pelo editado', () {
    final provider = EventoDetalheProvider(
      repository: FakeEventosDetalheRepository(),
      eventoInicial: eventoDeTeste(),
    );

    provider.atualizar(eventoDeTeste(titulo: 'Editado'));
    provider.atualizar(eventoDeTeste(id: 'outro', titulo: 'Outro evento'));

    expect(provider.evento?.titulo, 'Editado');
  });

  group('excluir', () {
    test('chama o repositório e devolve true', () async {
      final repo = FakeEventosDetalheRepository();
      final provider = EventoDetalheProvider(
        repository: repo,
        eventoInicial: eventoDeTeste(),
      );

      expect(await provider.excluir(), isTrue);
      expect(repo.excluidos, ['ev-1']);
      expect(provider.excluindo, isFalse);
    });

    test('se já não existia, conta como excluído', () async {
      final repo = FakeEventosDetalheRepository()
        ..erroExcluir = const EventoNaoEncontradoException();
      final provider = EventoDetalheProvider(
        repository: repo,
        eventoInicial: eventoDeTeste(),
      );

      expect(await provider.excluir(), isTrue);
    });

    test('sem permissão, devolve false com a mensagem', () async {
      final repo = FakeEventosDetalheRepository()
        ..erroExcluir = const EventoSemPermissaoException();
      final provider = EventoDetalheProvider(
        repository: repo,
        eventoInicial: eventoDeTeste(),
      );

      expect(await provider.excluir(), isFalse);
      expect(
        provider.mensagemErro,
        'Só quem organizou o evento pode alterá-lo.',
      );
      expect(provider.evento, isNotNull);
    });

    test('toque duplo não exclui duas vezes', () async {
      final segurar = Completer<void>();
      final repo = FakeEventosDetalheRepository()..segurarExcluir = segurar;
      final provider = EventoDetalheProvider(
        repository: repo,
        eventoInicial: eventoDeTeste(),
      );

      final primeiro = provider.excluir();
      expect(provider.excluindo, isTrue);
      expect(await provider.excluir(), isFalse);

      segurar.complete();
      expect(await primeiro, isTrue);
      expect(repo.excluidos, hasLength(1));
    });
  });
}
