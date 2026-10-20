import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/chat/data/conversas_repository.dart';
import 'package:pesque_fale_app/features/chat/domain/conversa.dart';
import 'package:pesque_fale_app/features/chat/providers/badge_mensagens_provider.dart';

Conversa _conv(String id, {required int naoLidas}) => Conversa(
  id: id,
  outroId: 'u-$id',
  outroNome: 'User $id',
  outroUsername: 'user_$id',
  outroFoto: null,
  ultimaMensagem: 'oi',
  ultimaMensagemEm: DateTime(2026, 10, 1),
  naoLidas: naoLidas,
  criadoEm: DateTime(2026, 9, 1),
);

class _FakeConversasRepository implements ConversasRepository {
  List<Conversa> conversas = const [];
  bool falhar = false;
  int chamadas = 0;
  Completer<List<Conversa>>? pendente;

  @override
  Future<List<Conversa>> listar() async {
    chamadas++;
    if (pendente != null) return pendente!.future;
    if (falhar) throw Exception('falha');
    return conversas;
  }
}

void main() {
  late _FakeConversasRepository repo;
  late BadgeMensagensProvider provider;
  late int notificacoes;

  setUp(() {
    repo = _FakeConversasRepository();
    provider = BadgeMensagensProvider(repository: repo);
    notificacoes = 0;
    provider.addListener(() => notificacoes++);
  });

  test('atualizar conta conversas com nao-lidas > 0 e notifica', () async {
    repo.conversas = [
      _conv('a', naoLidas: 3),
      _conv('b', naoLidas: 0),
      _conv('c', naoLidas: 1),
    ];

    await provider.atualizar();

    expect(provider.naoLidas, 2); // 2 conversas com não-lidas, não 4 mensagens
    expect(notificacoes, 1);
  });

  test('atualizar nao notifica quando a contagem nao muda', () async {
    repo.conversas = [_conv('a', naoLidas: 2)];
    await provider.atualizar();
    expect(notificacoes, 1);

    await provider.atualizar();
    expect(notificacoes, 1);
  });

  test('atualizar com falha nao propaga nem notifica', () async {
    repo.falhar = true;

    await provider.atualizar();

    expect(provider.naoLidas, 0);
    expect(notificacoes, 0);
  });

  test('duas chamadas concorrentes de atualizar nao fazem busca em dobro', () async {
    repo.pendente = Completer<List<Conversa>>();

    final f1 = provider.atualizar();
    final f2 = provider.atualizar();

    expect(repo.chamadas, 1);

    repo.pendente!.complete([_conv('a', naoLidas: 1)]);
    await Future.wait([f1, f2]);

    expect(provider.naoLidas, 1);
  });

  test('zerar coloca em 0 e notifica se estava diferente', () async {
    repo.conversas = [_conv('a', naoLidas: 1)];
    await provider.atualizar();
    expect(provider.naoLidas, 1);

    provider.zerar();

    expect(provider.naoLidas, 0);
    expect(notificacoes, 2);
  });

  test('zerar nao notifica se ja era 0', () {
    provider.zerar();

    expect(notificacoes, 0);
  });

  test('resetar invalida a geracao em andamento', () async {
    repo.pendente = Completer<List<Conversa>>();

    final f = provider.atualizar();
    provider.resetar();

    repo.pendente!.complete([_conv('a', naoLidas: 5)]);
    await f;

    expect(provider.naoLidas, 0); // o resultado tardio foi descartado
  });
}
