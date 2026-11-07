import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_exceptions.dart';
import 'package:pesque_fale_app/features/feed/data/upload_publicacao_imagem_exceptions.dart';
import 'package:pesque_fale_app/features/feed/domain/evento.dart';
import 'package:pesque_fale_app/features/novo_evento/providers/novo_evento_provider.dart';

import '../fakes.dart';

void main() {
  final agora = DateTime(2026, 11, 7, 10);
  final amanha = DateTime(2026, 11, 8, 7);

  late FakeEventosRepository repo;
  late FakeUploadRepository upload;

  setUp(() {
    repo = FakeEventosRepository();
    upload = FakeUploadRepository();
  });

  NovoEventoProvider criarProvider({Evento? evento}) => NovoEventoProvider(
    repository: repo,
    uploadRepository: upload,
    evento: evento,
    agora: () => agora,
  );

  NovoEventoProvider preenchido() => criarProvider()
    ..setTitulo('Torneio do Lago Azul')
    ..setDataInicio(amanha);

  final eventoSalvo = Evento(
    id: 'ev-1',
    titulo: 'Torneio antigo',
    descricao: 'Regras no local',
    pontoId: 'ponto-9',
    organizadorId: 'mock-id',
    organizadorNome: 'Ana',
    dataInicio: DateTime(2026, 11, 7, 6),
    dataFim: DateTime(2026, 11, 7, 18),
    imagemUrl: 'https://res.cloudinary.com/x/antiga.jpg',
    localTexto: 'Represa de Ibitinga',
    criadoEm: DateTime(2026, 11, 1),
  );

  group('validações antes de enviar', () {
    test('formulário válido não tem erros', () {
      expect(preenchido().validar(), isEmpty);
    });

    for (final titulo in ['', 'A', '   ', ' a ']) {
      test('título "$titulo" é recusado', () {
        final provider = preenchido()..setTitulo(titulo);

        expect(provider.validar().keys, ['titulo']);
      });
    }

    test('título com 2 e com 200 caracteres passa', () {
      expect((preenchido()..setTitulo('ab')).validar(), isEmpty);
      expect((preenchido()..setTitulo('a' * 200)).validar(), isEmpty);
      expect((preenchido()..setTitulo('a' * 201)).validar().keys, ['titulo']);
    });

    test('local escrito com mais de 150 caracteres é recusado', () {
      expect((preenchido()..setLocalTexto('a' * 150)).validar(), isEmpty);
      expect((preenchido()..setLocalTexto('a' * 151)).validar().keys, [
        'localTexto',
      ]);
    });

    test('sem início, pede a data e a hora', () {
      final provider = criarProvider()..setTitulo('Torneio');

      expect(provider.validar(), {
        'dataInicio': 'Escolha a data e a hora de início.',
      });
    });

    test('início no passado ou agora é recusado', () {
      expect(
        (preenchido()..setDataInicio(agora)).validar()['dataInicio'],
        'O início precisa ser depois de agora.',
      );
      expect(
        (preenchido()
              ..setDataInicio(agora.subtract(const Duration(minutes: 1))))
            .validar()
            .keys,
        ['dataInicio'],
      );
      expect(
        (preenchido()..setDataInicio(agora.add(const Duration(minutes: 1))))
            .validar(),
        isEmpty,
      );
    });

    test('fim igual ou antes do início é recusado', () {
      expect(
        (preenchido()..setDataFim(amanha)).validar()['dataFim'],
        'O fim precisa ser depois do início.',
      );
      expect(
        (preenchido()..setDataFim(amanha.subtract(const Duration(hours: 1))))
            .validar()
            .keys,
        ['dataFim'],
      );
      expect(
        (preenchido()..setDataFim(amanha.add(const Duration(minutes: 1))))
            .validar(),
        isEmpty,
      );
    });

    test('enviar com erro não chama o repositório e mostra os erros', () async {
      final provider = criarProvider();

      final resultado = await provider.enviar();

      expect(resultado, isNull);
      expect(repo.criados, isEmpty);
      expect(upload.enviados, isEmpty);
      expect(provider.erroDe('titulo'), isNotNull);
      expect(provider.erroDe('dataInicio'), isNotNull);
      expect(provider.status, StatusNovoEvento.erro);
    });

    test('mexer num campo apaga só o erro dele', () async {
      final provider = criarProvider();
      await provider.enviar();

      provider.setTitulo('Torneio');

      expect(provider.erroDe('titulo'), isNull);
      expect(provider.erroDe('dataInicio'), isNotNull);
    });
  });

  group('envio', () {
    test('cria com os campos limpos e devolve o evento', () async {
      final provider = preenchido()
        ..setTitulo('  Torneio do Lago Azul  ')
        ..setDescricao('  ')
        ..setLocalTexto(' Lago Azul, Matão-SP ')
        ..setDataFim(amanha.add(const Duration(hours: 5)));

      final evento = await provider.enviar();

      expect(evento?.id, 'ev-novo');
      expect(provider.status, StatusNovoEvento.sucesso);
      final dados = repo.criados.single;
      expect(dados.titulo, 'Torneio do Lago Azul');
      expect(dados.descricao, isNull);
      expect(dados.localTexto, 'Lago Azul, Matão-SP');
      expect(dados.pontoId, isNull);
      expect(dados.dataInicio, amanha);
      expect(dados.dataFim, amanha.add(const Duration(hours: 5)));
      expect(dados.imagemUrl, isNull);
      expect(upload.enviados, isEmpty);
    });

    test('com ponto escolhido, manda o id e o nome do ponto', () async {
      final provider = preenchido()
        ..setLocalTexto('texto que fica de lado')
        ..setPonto(
          const PontoDoEvento(id: 'p-1', nome: 'Lago Azul', regiao: 'Matão-SP'),
        );

      await provider.enviar();

      expect(repo.criados.single.pontoId, 'p-1');
      expect(repo.criados.single.localTexto, 'Lago Azul');
    });

    test('foto: faz o upload antes de criar e manda a URL', () async {
      final provider = preenchido()
        ..setFoto(
          bytes: Uint8List(4),
          filename: 'lago.jpg',
          mimeType: 'image/jpeg',
        );

      await provider.enviar();

      expect(upload.enviados, ['lago.jpg']);
      expect(
        repo.criados.single.imagemUrl,
        'https://res.cloudinary.com/x/lago.jpg',
      );
    });

    test('foto grande demais: mostra a mensagem e não cria', () async {
      upload.erro = UploadArquivoMuitoGrandeException();
      final provider = preenchido()
        ..setFoto(
          bytes: Uint8List(4),
          filename: 'g.jpg',
          mimeType: 'image/jpeg',
        );

      expect(await provider.enviar(), isNull);

      expect(repo.criados, isEmpty);
      expect(
        provider.mensagemErro,
        'A imagem é maior que 5MB. Escolha uma menor.',
      );
      expect(provider.status, StatusNovoEvento.erro);
    });

    test(
      'se o criar falhar depois do upload, tentar de novo não sobe a foto outra vez',
      () async {
        repo.erro = const EventosRedeException();
        final provider = preenchido()
          ..setFoto(
            bytes: Uint8List(4),
            filename: 'lago.jpg',
            mimeType: 'image/jpeg',
          );

        await provider.enviar();
        expect(provider.mensagemErro, 'Sem conexão com o servidor.');

        repo.erro = null;
        await provider.enviar();

        expect(upload.enviados, ['lago.jpg']);
        expect(
          repo.criados.last.imagemUrl,
          'https://res.cloudinary.com/x/lago.jpg',
        );
      },
    );

    test('erro 400 da API aparece no campo certo', () async {
      repo.erro = EventoValidacaoException({
        'titulo': 'Título deve ter entre 2 e 200 caracteres.',
        'dataFim':
            'A data de fim deve ser igual ou posterior à data de início.',
      });
      final provider = preenchido();

      expect(await provider.enviar(), isNull);

      expect(
        provider.erroDe('titulo'),
        'Título deve ter entre 2 e 200 caracteres.',
      );
      expect(
        provider.erroDe('dataFim'),
        'A data de fim deve ser igual ou posterior à data de início.',
      );
      expect(provider.mensagemErro, 'Confira os campos destacados.');
      expect(provider.status, StatusNovoEvento.erro);
    });

    test('erro 400 sem campos usa a mensagem da API', () async {
      repo.erro = EventoValidacaoException(const {});
      final provider = preenchido();

      await provider.enviar();

      expect(provider.errosPorCampo, isEmpty);
      expect(provider.mensagemErro, 'Verifique os campos e tente novamente.');
    });

    test(
      'toque duplo: o segundo enviar é ignorado enquanto o primeiro está em voo',
      () async {
        final segurar = Completer<void>();
        repo.segurar = segurar;
        final provider = preenchido();

        final primeiro = provider.enviar();
        final segundo = provider.enviar();
        expect(provider.enviando, isTrue);
        expect(await segundo, isNull);

        segurar.complete();
        expect(await primeiro, isNotNull);
        expect(repo.criados, hasLength(1));
      },
    );

    test(
      'formulário sujo só depois de mexer, e limpo depois do sucesso',
      () async {
        final provider = criarProvider();
        expect(provider.formularioSujo, isFalse);

        provider
          ..setTitulo('Torneio')
          ..setDataInicio(amanha);
        expect(provider.formularioSujo, isTrue);

        await provider.enviar();
        expect(provider.formularioSujo, isFalse);
      },
    );
  });

  group('edição', () {
    test('começa preenchido com o evento', () {
      final provider = criarProvider(evento: eventoSalvo);

      expect(provider.editando, isTrue);
      expect(provider.titulo, 'Torneio antigo');
      expect(provider.descricao, 'Regras no local');
      expect(provider.dataInicio, eventoSalvo.dataInicio);
      expect(provider.dataFim, eventoSalvo.dataFim);
      expect(provider.ponto?.id, 'ponto-9');
      expect(provider.ponto?.nome, 'Represa de Ibitinga');
      expect(provider.imagemUrlAtual, eventoSalvo.imagemUrl);
      expect(provider.formularioSujo, isFalse);
    });

    test('salva com editar, mantendo foto e ponto', () async {
      final provider = criarProvider(evento: eventoSalvo)
        ..setTitulo('Torneio novo');

      final salvo = await provider.enviar();

      expect(repo.criados, isEmpty);
      final (id, dados) = repo.editados.single;
      expect(id, 'ev-1');
      expect(salvo?.id, 'ev-1');
      expect(dados.titulo, 'Torneio novo');
      expect(dados.pontoId, 'ponto-9');
      expect(dados.localTexto, 'Represa de Ibitinga');
      expect(dados.imagemUrl, eventoSalvo.imagemUrl);
      expect(upload.enviados, isEmpty);
    });

    test('evento já começado pode ser editado sem mexer no início', () async {
      final provider = criarProvider(evento: eventoSalvo)
        ..setTitulo('Torneio novo');

      expect(provider.validar(), isEmpty);
      expect(await provider.enviar(), isNotNull);
    });

    test('trocar o início para o passado é recusado na edição', () {
      final provider = criarProvider(evento: eventoSalvo)
        ..setDataInicio(DateTime(2026, 11, 7, 5));

      expect(provider.validar().keys, ['dataInicio']);
    });

    test('remover a foto e o fim manda null', () async {
      final provider = criarProvider(evento: eventoSalvo)
        ..removerFoto()
        ..setDataFim(null);

      await provider.enviar();

      final (_, dados) = repo.editados.single;
      expect(dados.imagemUrl, isNull);
      expect(dados.dataFim, isNull);
    });

    test('trocar o ponto por texto livre tira o pontoId', () async {
      final provider = criarProvider(evento: eventoSalvo)
        ..setPonto(null)
        ..setLocalTexto('Rio Mogi');

      await provider.enviar();

      final (_, dados) = repo.editados.single;
      expect(dados.pontoId, isNull);
      expect(dados.localTexto, 'Rio Mogi');
    });

    test('evento sem ponto começa com o local escrito', () {
      final provider = criarProvider(
        evento: Evento(
          id: 'ev-2',
          titulo: 'Pescaria',
          organizadorId: 'mock-id',
          organizadorNome: 'Ana',
          dataInicio: amanha,
          localTexto: 'Rio Mogi',
          criadoEm: DateTime(2026, 11, 1),
        ),
      );

      expect(provider.ponto, isNull);
      expect(provider.localTexto, 'Rio Mogi');
    });
  });
}
