import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/notificacoes/data/notificacoes_repository.dart';
import 'package:pesque_fale_app/features/notificacoes/domain/notificacao.dart';
import 'package:pesque_fale_app/features/notificacoes/providers/badge_notificacoes_provider.dart';

class _FakeNotificacoesRepository implements NotificacoesRepository {
  int naoLidas = 0;
  bool falhar = false;
  int chamadasContar = 0;
  Completer<int>? pendente;

  @override
  Future<int> contarNaoLidas() async {
    chamadasContar++;
    if (pendente != null) return pendente!.future;
    if (falhar) throw Exception('falha');
    return naoLidas;
  }

  @override
  Future<({List<Notificacao> lista, int naoLidas})> listar({
    int pagina = 1,
    int porPagina = 20,
  }) async => (lista: const <Notificacao>[], naoLidas: naoLidas);

  @override
  Future<void> marcarTodasComoLidas() async {}
}

void main() {
  late _FakeNotificacoesRepository repo;
  late BadgeNotificacoesProvider provider;
  late int notificacoes;

  setUp(() {
    repo = _FakeNotificacoesRepository();
    provider = BadgeNotificacoesProvider(repository: repo);
    notificacoes = 0;
    provider.addListener(() => notificacoes++);
  });

  test('atualizar busca a contagem de não lidas e notifica', () async {
    repo.naoLidas = 3;

    await provider.atualizar();

    expect(provider.naoLidas, 3);
    expect(notificacoes, 1);
  });

  test('atualizar não notifica quando a contagem não muda', () async {
    repo.naoLidas = 2;
    await provider.atualizar();

    await provider.atualizar();

    expect(provider.naoLidas, 2);
    expect(notificacoes, 1);
  });

  test('atualizar reflete notificações novas que chegam depois', () async {
    repo.naoLidas = 1;
    await provider.atualizar();

    repo.naoLidas = 4;
    await provider.atualizar();

    expect(provider.naoLidas, 4);
  });

  test('atualizar mantém o contador atual quando o repositório falha', () async {
    repo.naoLidas = 5;
    await provider.atualizar();

    repo.falhar = true;
    await provider.atualizar();

    expect(provider.naoLidas, 5);
  });

  test('zerar zera o contador e notifica', () async {
    repo.naoLidas = 2;
    await provider.atualizar();

    provider.zerar();

    expect(provider.naoLidas, 0);
    expect(notificacoes, 2);
  });

  test('zerar descarta a resposta de um atualizar que já estava em andamento', () async {
    repo.pendente = Completer<int>();
    final emAndamento = provider.atualizar();

    provider.zerar();
    repo.pendente!.complete(7);
    await emAndamento;

    expect(provider.naoLidas, 0);
  });

  test('ignora chamadas de atualizar enquanto outra está em andamento', () async {
    repo.pendente = Completer<int>();
    final primeira = provider.atualizar();
    final segunda = provider.atualizar();

    repo.pendente!.complete(1);
    await Future.wait([primeira, segunda]);

    expect(repo.chamadasContar, 1);
    expect(provider.naoLidas, 1);
  });
}