import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/assistente/data/assistente_exceptions.dart';
import 'package:pesque_fale_app/features/assistente/data/assistente_repository.dart';
import 'package:pesque_fale_app/features/assistente/domain/mensagem_assistente.dart';
import 'package:pesque_fale_app/features/assistente/providers/assistente_provider.dart';

class _FakeAssistenteRepository implements AssistenteRepository {
  final List<String> perguntas = [];
  final List<List<MensagemAssistente>> historicos = [];
  Completer<RespostaAssistente>? pendente;
  Object? erro;

  @override
  Future<RespostaAssistente> perguntar({
    required String mensagem,
    required List<MensagemAssistente> historico,
    String? tela,
  }) {
    perguntas.add(mensagem);
    historicos.add(historico);
    if (pendente != null) return pendente!.future;
    if (erro != null) return Future.error(erro!);
    return Future.value(
      RespostaAssistente(
        resposta: 'Resposta para $mensagem',
        acoes: const [
          AcaoAssistente(
            tipo: TipoAcaoAssistente.abrirTela,
            rotulo: 'Abrir',
            tela: 'chat',
          ),
        ],
      ),
    );
  }
}

void main() {
  late _FakeAssistenteRepository repo;
  late AssistenteProvider provider;

  setUp(() {
    repo = _FakeAssistenteRepository();
    provider = AssistenteProvider(
      repository: repo,
      avisoDemora: const Duration(milliseconds: 1),
    );
  });

  test('começa vazio, com sugestões prontas', () {
    expect(provider.conversaVazia, isTrue);
    expect(AssistenteProvider.sugestoes, isNotEmpty);
  });

  test('envia a pergunta e guarda a resposta com as ações', () async {
    await provider.enviar('  Como publico?  ');

    expect(repo.perguntas, ['Como publico?']);
    expect(provider.mensagens, hasLength(2));
    expect(provider.mensagens[0].doUsuario, isTrue);
    expect(provider.mensagens[0].texto, 'Como publico?');
    expect(provider.mensagens[1].texto, 'Resposta para Como publico?');
    expect(provider.mensagens[1].acoes.single.tela, 'chat');
    expect(provider.enviando, isFalse);
    expect(provider.erro, isNull);
  });

  test('ignora pergunta vazia', () async {
    await provider.enviar('   ');
    expect(repo.perguntas, isEmpty);
    expect(provider.conversaVazia, isTrue);
  });

  test('ignora nova pergunta enquanto espera a resposta', () async {
    repo.pendente = Completer();
    final primeira = provider.enviar('Primeira');
    await provider.enviar('Segunda');

    expect(provider.enviando, isTrue);
    expect(repo.perguntas, ['Primeira']);

    repo.pendente!.complete(const RespostaAssistente(resposta: 'Ok'));
    await primeira;
    expect(provider.enviando, isFalse);
  });

  test('manda só as 6 mensagens anteriores como histórico', () async {
    for (var i = 0; i < 5; i++) {
      await provider.enviar('Pergunta $i');
    }

    final ultimoHistorico = repo.historicos.last;
    expect(ultimoHistorico, hasLength(6));
    expect(ultimoHistorico.first.texto, 'Pergunta 1');
    expect(ultimoHistorico.last.texto, 'Resposta para Pergunta 3');
  });

  test('avisa quando a resposta demora', () async {
    repo.pendente = Completer();
    final envio = provider.enviar('Oi');

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(provider.demorando, isTrue);

    repo.pendente!.complete(const RespostaAssistente(resposta: 'Ok'));
    await envio;
    expect(provider.demorando, isFalse);
  });

  test('erro mostra a mensagem amigável e permite tentar de novo', () async {
    repo.erro = const AssistenteIndisponivelException();
    await provider.enviar('Oi');

    expect(provider.erro, const AssistenteIndisponivelException().message);
    expect(provider.mensagens, hasLength(1));

    repo.erro = null;
    await provider.tentarDeNovo();

    expect(repo.perguntas, ['Oi', 'Oi']);
    expect(repo.historicos.last, isEmpty);
    expect(provider.erro, isNull);
    expect(provider.mensagens, hasLength(2));
    expect(provider.mensagens.last.texto, 'Resposta para Oi');
  });

  test('erro inesperado vira mensagem genérica', () async {
    repo.erro = StateError('boom');
    await provider.enviar('Oi');
    expect(provider.erro, const InternalServerException().message);
  });

  test('descartar durante a resposta não quebra', () async {
    repo.pendente = Completer();
    final envio = provider.enviar('Oi');
    provider.dispose();

    repo.pendente!.complete(const RespostaAssistente(resposta: 'Ok'));
    await envio;
  });
}