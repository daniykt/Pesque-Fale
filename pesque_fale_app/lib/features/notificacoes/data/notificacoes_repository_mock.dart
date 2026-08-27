import '../domain/notificacao.dart';
import 'notificacoes_repository.dart';

class NotificacoesRepositoryMock implements NotificacoesRepository {
  static const _delay = Duration(milliseconds: 400);

  final List<Notificacao> _todas = _gerar();

  @override
  Future<({List<Notificacao> lista, int naoLidas})> listar({
    int pagina = 1,
    int porPagina = 20,
  }) async {
    await Future.delayed(_delay);
    return (
      lista: List<Notificacao>.unmodifiable(_todas),
      naoLidas: _todas.where((n) => !n.lida).length,
    );
  }

  @override
  Future<int> contarNaoLidas() async {
    await Future.delayed(_delay);
    return _todas.where((n) => !n.lida).length;
  }

  @override
  Future<void> marcarTodasComoLidas() async {
    await Future.delayed(_delay);
    for (var i = 0; i < _todas.length; i++) {
      _todas[i] = _todas[i].copyWith(lida: true);
    }
  }

  static List<Notificacao> _gerar() {
    final agora = DateTime.now();
    return [
      Notificacao(
        id: 'notif_1',
        para: 'me',
        deId: 'user_1',
        de: 'Henrique Tavares',
        deUsername: 'rique',
        deFoto: null,
        tipo: TipoNotificacao.seguindo,
        lida: false,
        jaSigoDe: false,
        criadoEm: agora.subtract(const Duration(minutes: 5)),
      ),
      Notificacao(
        id: 'notif_2',
        para: 'me',
        deId: 'user_2',
        de: 'loiro_misterio',
        deUsername: 'loiro',
        deFoto: null,
        tipo: TipoNotificacao.curtida,
        postId: 'post_1',
        lida: false,
        criadoEm: agora.subtract(const Duration(hours: 1)),
      ),
      Notificacao(
        id: 'notif_3',
        para: 'me',
        deId: 'user_3',
        de: 'Beatriz Fisher',
        deUsername: 'bia_fisher',
        deFoto: null,
        tipo: TipoNotificacao.comentario,
        texto: 'Que peixe grande! Onde foi essa pescaria mesmo?',
        postId: 'post_2',
        lida: false,
        criadoEm: agora.subtract(const Duration(hours: 3)),
      ),
      Notificacao(
        id: 'notif_4',
        para: 'me',
        deId: 'user_4',
        de: 'Marcelo Andrade',
        deUsername: 'marceloandrade',
        deFoto: null,
        tipo: TipoNotificacao.mensagem,
        texto: 'Valeu pela dica do isca, bora marcar outra?',
        chatId: 'chat_5',
        lida: true,
        criadoEm: agora.subtract(const Duration(days: 1)),
      ),
      Notificacao(
        id: 'notif_5',
        para: 'me',
        deId: 'user_5',
        de: 'João Pedro Montrezor',
        deUsername: 'joaop',
        deFoto: null,
        tipo: TipoNotificacao.seguindo,
        lida: true,
        jaSigoDe: true,
        criadoEm: agora.subtract(const Duration(days: 2)),
      ),
      Notificacao(
        id: 'notif_6',
        para: 'me',
        tipo: TipoNotificacao.sistema,
        texto: 'Bem-vindo ao Pesque & Fale! Complete seu perfil.',
        lida: true,
        criadoEm: agora.subtract(const Duration(days: 5)),
      ),
      Notificacao(
        id: 'notif_7',
        para: 'me',
        deId: 'user_2',
        de: 'loiro_misterio',
        deUsername: 'loiro',
        deFoto: null,
        tipo: TipoNotificacao.curtida,
        postId: 'post_3',
        lida: true,
        criadoEm: agora.subtract(const Duration(days: 10)),
      ),
      Notificacao(
        id: 'notif_8',
        para: 'me',
        deId: 'user_3',
        de: 'Beatriz Fisher',
        deUsername: 'bia_fisher',
        deFoto: null,
        tipo: TipoNotificacao.comentario,
        texto: 'Marca aí quando for de novo!',
        postId: 'post_4',
        lida: true,
        criadoEm: agora.subtract(const Duration(days: 40)),
      ),
    ];
  }
}
