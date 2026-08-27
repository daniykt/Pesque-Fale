import '../domain/conversa.dart';
import 'conversas_repository.dart';

class ConversasRepositoryMock implements ConversasRepository {
  static const _delay = Duration(milliseconds: 400);

  @override
  Future<List<Conversa>> listar() async {
    await Future.delayed(_delay);
    final agora = DateTime.now();
    return [
      Conversa(
        id: 'chat_1',
        outroId: 'user_1',
        outroNome: 'Henrique Tavares',
        outroUsername: 'rique',
        outroFoto: null,
        ultimaMensagem: 'Eai',
        ultimaMensagemEm: agora.subtract(const Duration(hours: 2)),
        naoLidas: 0,
        criadoEm: agora.subtract(const Duration(days: 30)),
      ),
      Conversa(
        id: 'chat_2',
        outroId: 'user_2',
        outroNome: 'loiro_misterio 👀',
        outroUsername: 'loiro',
        outroFoto: null,
        ultimaMensagem: 'seu maluco',
        ultimaMensagemEm: agora.subtract(const Duration(days: 3)),
        naoLidas: 18,
        criadoEm: agora.subtract(const Duration(days: 60)),
      ),
      Conversa(
        id: 'chat_4',
        outroId: 'user_4',
        outroNome: 'Beatriz Fisher',
        outroUsername: 'bia_fisher',
        outroFoto: null,
        ultimaMensagem: 'Bora pescar sábado?',
        ultimaMensagemEm: agora.subtract(const Duration(minutes: 5)),
        naoLidas: 120,
        criadoEm: agora.subtract(const Duration(days: 10)),
      ),
      Conversa(
        id: 'chat_5',
        outroId: 'user_5',
        outroNome: 'Marcelo Andrade',
        outroUsername: 'marceloandrade',
        outroFoto: null,
        ultimaMensagem: 'Valeu pela dica do isca!',
        ultimaMensagemEm: agora.subtract(const Duration(days: 400)),
        naoLidas: 0,
        criadoEm: agora.subtract(const Duration(days: 500)),
      ),
      Conversa(
        id: 'chat_3',
        outroId: 'user_3',
        outroNome: 'João Pedro Montrezor',
        outroUsername: 'joaop',
        outroFoto: null,
        ultimaMensagem: null,
        ultimaMensagemEm: null,
        naoLidas: 0,
        criadoEm: agora.subtract(const Duration(days: 5)),
      ),
    ];
  }
}
