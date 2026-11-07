import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/clima/data/clima_exceptions.dart';
import 'package:pesque_fale_app/features/clima/data/clima_repository.dart';
import 'package:pesque_fale_app/features/clima/data/localizacao_service.dart';
import 'package:pesque_fale_app/features/clima/domain/clima.dart';
import 'package:pesque_fale_app/features/clima/domain/condicao_clima.dart';
import 'package:pesque_fale_app/features/clima/providers/clima_provider.dart';

const _clima = Clima(
  temperatura: 24.6,
  umidade: 71,
  ventoKmh: 9.4,
  condicao: CondicaoClima.nublado,
);

class FakeClimaRepository implements ClimaRepository {
  Object? erro;
  int chamadas = 0;
  Completer<void>? segurar;
  ({double latitude, double longitude})? ultimaCoordenada;

  @override
  Future<Clima> buscarAtual({
    required double latitude,
    required double longitude,
  }) async {
    chamadas++;
    ultimaCoordenada = (latitude: latitude, longitude: longitude);
    await segurar?.future;
    final e = erro;
    if (e != null) throw e;
    return _clima;
  }
}

class FakeLocalizacao implements LocalizacaoService {
  ResultadoLocalizacao resultado = const LocalizacaoObtida(
    latitude: -21.6,
    longitude: -48.36,
  );
  final List<bool> pedidos = [];
  final List<MotivoSemLocalizacao> configuracoesAbertas = [];

  @override
  Future<ResultadoLocalizacao> obter({required bool pedirPermissao}) async {
    pedidos.add(pedirPermissao);
    return resultado;
  }

  @override
  Future<void> abrirConfiguracoes(MotivoSemLocalizacao motivo) async {
    configuracoesAbertas.add(motivo);
  }
}

void main() {
  late FakeClimaRepository repo;
  late FakeLocalizacao localizacao;
  late ClimaProvider provider;
  late DateTime agora;

  setUp(() {
    repo = FakeClimaRepository();
    localizacao = FakeLocalizacao();
    agora = DateTime(2026, 11, 6, 15);
    provider = ClimaProvider(
      repository: repo,
      localizacao: localizacao,
      agora: () => agora,
    );
  });

  test('começa em inicial, sem clima', () {
    expect(provider.status, StatusClima.inicial);
    expect(provider.clima, isNull);
  });

  test('abrir pela primeira vez pede permissão e mostra o clima', () async {
    final estados = <StatusClima>[];
    provider.addListener(() => estados.add(provider.status));

    await provider.abrir();

    expect(localizacao.pedidos, [true]);
    expect(repo.ultimaCoordenada, (latitude: -21.6, longitude: -48.36));
    expect(estados, [StatusClima.carregando, StatusClima.sucesso]);
    expect(provider.clima, same(_clima));
    expect(provider.hoje, DateTime(2026, 11, 6, 15));
  });

  test('abrir de novo e puxar para atualizar não pedem permissão', () async {
    await provider.abrir();
    agora = agora.add(const Duration(minutes: 11));

    await provider.abrir();
    await provider.atualizar();

    expect(localizacao.pedidos, [true, false, false]);
    expect(repo.chamadas, 3);
  });

  group('validade de 10 minutos', () {
    test('abrir antes de 10 minutos reaproveita o clima, sem buscar', () async {
      await provider.abrir();
      agora = agora.add(const Duration(minutes: 9, seconds: 59));

      await provider.abrir();

      expect(repo.chamadas, 1);
      expect(localizacao.pedidos, [true]);
      expect(provider.status, StatusClima.sucesso);
    });

    test('abrir com 10 minutos ou mais busca de novo', () async {
      await provider.abrir();
      agora = agora.add(ClimaProvider.validadeDoClima);

      await provider.abrir();

      expect(repo.chamadas, 2);
    });

    test('atualizar sempre busca, mesmo dentro dos 10 minutos', () async {
      await provider.abrir();
      agora = agora.add(const Duration(minutes: 1));

      await provider.atualizar();

      expect(repo.chamadas, 2);
    });

    test('a validade conta a partir da última busca', () async {
      await provider.abrir();
      agora = agora.add(const Duration(minutes: 8));
      await provider.atualizar();
      agora = agora.add(const Duration(minutes: 8));

      await provider.abrir();

      expect(repo.chamadas, 2, reason: 'só 8 minutos desde o atualizar');
    });

    test('depois de um erro, abrir busca de novo', () async {
      repo.erro = const ClimaRedeException();
      await provider.abrir();
      repo.erro = null;

      await provider.abrir();

      expect(repo.chamadas, 2);
      expect(provider.status, StatusClima.sucesso);
    });

    test(
      'sem localização, abrir confere de novo mesmo dentro dos 10 minutos',
      () async {
        localizacao.resultado = const LocalizacaoIndisponivel(
          MotivoSemLocalizacao.negada,
        );
        await provider.abrir();

        await provider.abrir();

        expect(localizacao.pedidos, hasLength(2));
      },
    );
  });

  test(
    'sem permissão: estado sem localização, sem clima e sem chamar a API',
    () async {
      localizacao.resultado = const LocalizacaoIndisponivel(
        MotivoSemLocalizacao.negada,
      );

      await provider.abrir();

      expect(provider.status, StatusClima.semLocalizacao);
      expect(provider.motivoSemLocalizacao, MotivoSemLocalizacao.negada);
      expect(provider.clima, isNull);
      expect(repo.chamadas, 0);
    },
  );

  test('voltar à aba sem permissão não insiste no pedido', () async {
    localizacao.resultado = const LocalizacaoIndisponivel(
      MotivoSemLocalizacao.negada,
    );
    await provider.abrir();

    await provider.abrir();

    expect(localizacao.pedidos, [true, false]);
  });

  test(
    'permitir com permissão negada pede de novo, sem abrir configurações',
    () async {
      localizacao.resultado = const LocalizacaoIndisponivel(
        MotivoSemLocalizacao.negada,
      );
      await provider.abrir();
      localizacao.resultado = const LocalizacaoObtida(
        latitude: -21.6,
        longitude: -48.36,
      );

      await provider.permitirLocalizacao();

      expect(localizacao.configuracoesAbertas, isEmpty);
      expect(localizacao.pedidos.last, isTrue);
      expect(provider.status, StatusClima.sucesso);
    },
  );

  test(
    'permitir com bloqueio ou GPS desligado abre as configurações certas',
    () async {
      for (final motivo in [
        MotivoSemLocalizacao.negadaParaSempre,
        MotivoSemLocalizacao.servicoDesligado,
      ]) {
        localizacao.resultado = LocalizacaoIndisponivel(motivo);
        await provider.atualizar();

        await provider.permitirLocalizacao();

        expect(localizacao.configuracoesAbertas.last, motivo);
      }
    },
  );

  test('erro de rede: estado de erro com a mensagem, sem clima', () async {
    repo.erro = const ClimaRedeException();

    await provider.abrir();

    expect(provider.status, StatusClima.erro);
    expect(provider.mensagemErro, const ClimaRedeException().message);
    expect(provider.clima, isNull);
  });

  test(
    'erro depois de um sucesso não continua mostrando o clima antigo',
    () async {
      await provider.abrir();
      repo.erro = const ClimaServicoException();

      await provider.atualizar();

      expect(provider.status, StatusClima.erro);
      expect(provider.clima, isNull);
    },
  );

  test('erro inesperado vira mensagem genérica', () async {
    localizacao.resultado = const LocalizacaoObtida(latitude: 0, longitude: 0);
    repo.erro = StateError('qualquer coisa');

    await provider.abrir();

    expect(provider.status, StatusClima.erro);
    expect(provider.mensagemErro, 'Não foi possível obter o clima agora.');
  });

  test('tentar de novo depois do erro busca e mostra o clima', () async {
    repo.erro = const ClimaRedeException();
    await provider.abrir();
    repo.erro = null;

    await provider.atualizar();

    expect(provider.status, StatusClima.sucesso);
    expect(provider.mensagemErro, isNull);
  });

  test('chamadas simultâneas fazem uma busca só', () async {
    repo.segurar = Completer<void>();

    final primeira = provider.abrir();
    final segunda = provider.atualizar();
    final terceira = provider.abrir();
    repo.segurar!.complete();
    await Future.wait([primeira, segunda, terceira]);

    expect(repo.chamadas, 1);
    expect(localizacao.pedidos, hasLength(1));
  });
}
