import '../domain/notificacao.dart';

abstract class NotificacoesRepository {
  Future<({List<Notificacao> lista, int naoLidas})> listar({
    int pagina = 1,
    int porPagina = 20,
  });

  Future<int> contarNaoLidas();

  Future<void> marcarTodasComoLidas();
}
