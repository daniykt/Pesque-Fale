import '../domain/notificacao.dart';
import 'notificacoes_api_client.dart';
import 'notificacoes_repository.dart';

class NotificacoesRepositoryHttp implements NotificacoesRepository {
  NotificacoesRepositoryHttp({required this.apiClient});

  final NotificacoesApiClient apiClient;

  @override
  Future<({List<Notificacao> lista, int naoLidas})> listar({
    int pagina = 1,
    int porPagina = 20,
  }) async {
    final json = await apiClient.listar(pagina: pagina, porPagina: porPagina);
    final data = (json['data'] as List<dynamic>?) ?? const [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return (
      lista: data
          .map((e) => Notificacao.fromJson(e as Map<String, dynamic>))
          .toList(),
      naoLidas: meta['naoLidas'] as int? ?? 0,
    );
  }

  @override
  Future<int> contarNaoLidas() async {
    final json = await apiClient.contarNaoLidas();
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    return data['naoLidas'] as int? ?? 0;
  }

  @override
  Future<void> marcarTodasComoLidas() => apiClient.marcarTodasComoLidas();
}
