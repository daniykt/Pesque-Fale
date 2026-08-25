import '../domain/evento.dart';
import 'eventos_api_client.dart';
import 'eventos_repository.dart';

class EventosRepositoryHttp implements EventosRepository {
  EventosRepositoryHttp({required this.apiClient});

  final EventosApiClient apiClient;

  @override
  Future<List<Evento>> listar({bool futuros = true, int limite = 10}) async {
    final json = await apiClient.listar(futuros: futuros, porPagina: limite);
    final data = (json['data'] as List<dynamic>?) ?? const [];
    return data.map((e) => Evento.fromJson(e as Map<String, dynamic>)).toList();
  }
}
