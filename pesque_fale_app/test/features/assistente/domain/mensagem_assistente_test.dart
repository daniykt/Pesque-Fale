import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/assistente/domain/mensagem_assistente.dart';

void main() {
  test('converte a resposta da API com ações de local e de tela', () {
    final resposta = RespostaAssistente.fromJson({
      'resposta': '  O Lago Azul fica em Matão.  ',
      'acoes': [
        {'tipo': 'abrir_local', 'pontoId': 'p1', 'rotulo': 'Ver Lago Azul'},
        {'tipo': 'abrir_tela', 'tela': 'nova_publicacao', 'rotulo': 'Publicar'},
      ],
    });

    expect(resposta.resposta, 'O Lago Azul fica em Matão.');
    expect(resposta.acoes, hasLength(2));
    expect(resposta.acoes[0].tipo, TipoAcaoAssistente.abrirLocal);
    expect(resposta.acoes[0].pontoId, 'p1');
    expect(resposta.acoes[1].tipo, TipoAcaoAssistente.abrirTela);
    expect(resposta.acoes[1].tela, 'nova_publicacao');
  });

  test('descarta ações desconhecidas ou incompletas', () {
    final resposta = RespostaAssistente.fromJson({
      'resposta': 'Oi',
      'acoes': [
        {'tipo': 'apagar_tudo', 'rotulo': 'Apagar'},
        {'tipo': 'abrir_local', 'rotulo': 'Sem id'},
        {'tipo': 'abrir_tela', 'tela': 'chat'},
        'texto solto',
      ],
    });

    expect(resposta.acoes, isEmpty);
  });

  test('sem lista de ações devolve lista vazia', () {
    final resposta = RespostaAssistente.fromJson({'resposta': 'Oi'});
    expect(resposta.acoes, isEmpty);
  });

  test('converte mensagens para o histórico da API', () {
    const usuario = MensagemAssistente.usuario('Como publico?');
    const assistente = MensagemAssistente(
      autor: AutorMensagem.assistente,
      texto: 'Toque em Publicar.',
    );

    expect(usuario.toHistorico(), {'papel': 'usuario', 'texto': 'Como publico?'});
    expect(assistente.toHistorico(), {
      'papel': 'assistente',
      'texto': 'Toque em Publicar.',
    });
  });
}