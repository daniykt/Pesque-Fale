import '../domain/mensagem_assistente.dart';
import 'assistente_repository.dart';

class AssistenteRepositoryMock implements AssistenteRepository {
  AssistenteRepositoryMock({this.atraso = const Duration(milliseconds: 600)});

  final Duration atraso;

  @override
  Future<RespostaAssistente> perguntar({
    required String mensagem,
    required List<MensagemAssistente> historico,
    String? tela,
  }) async {
    await Future<void>.delayed(atraso);
    final texto = mensagem.toLowerCase();

    if (texto.contains('sabe fazer') || texto.contains('pode ajudar')) {
      return const RespostaAssistente(
        resposta:
            'Eu explico como usar o Pesque & Fale, como publicar uma pescaria, mudar seu perfil ou seguir pessoas, e abro a tela certa com um botão. Também procuro locais de pesca cadastrados. Você pode falar a pergunta no microfone e tocar em Ouvir para escutar a resposta.',
      );
    }

    if (texto.contains('public')) {
      return const RespostaAssistente(
        resposta:
            '1. Toque no botão abaixo.\n2. Escolha uma foto da pescaria.\n3. Conte como foi e escolha o local.\n4. Toque em Publicar.',
        acoes: [
          AcaoAssistente(
            tipo: TipoAcaoAssistente.abrirTela,
            rotulo: 'Abrir tela de publicar',
            tela: 'nova_publicacao',
          ),
        ],
      );
    }

    if (texto.contains('lago') || texto.contains('local')) {
      return const RespostaAssistente(
        resposta: 'O Lago Azul fica em Campinas, SP. Toque no botão para ver os detalhes.',
        acoes: [
          AcaoAssistente(
            tipo: TipoAcaoAssistente.abrirLocal,
            rotulo: 'Ver Lago Azul',
            pontoId: '7',
          ),
        ],
      );
    }

    if (texto.contains('foto') || texto.contains('perfil')) {
      return const RespostaAssistente(
        resposta: 'Toque no botão abaixo e depois na sua foto para trocar.',
        acoes: [
          AcaoAssistente(
            tipo: TipoAcaoAssistente.abrirTela,
            rotulo: 'Abrir editar perfil',
            tela: 'editar_perfil',
          ),
        ],
      );
    }

    return const RespostaAssistente(
      resposta:
          'Posso te ajudar a usar o Pesque & Fale: publicar uma pescaria, encontrar locais ou mudar seu perfil.',
    );
  }
}