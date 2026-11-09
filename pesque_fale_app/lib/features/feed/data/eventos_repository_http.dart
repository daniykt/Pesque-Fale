import '../domain/dados_evento.dart';
import '../domain/evento.dart';
import 'eventos_api_client.dart';
import 'eventos_exceptions.dart';
import 'eventos_repository.dart';

class EventosRepositoryHttp implements EventosRepository {
  EventosRepositoryHttp({required this.apiClient});

  final EventosApiClient apiClient;

  @override
  Future<List<Evento>> listar({bool futuros = true, int limite = 10}) async {
    final json = await apiClient.listar(futuros: futuros, porPagina: limite);
    final data = json['data'];
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().map(Evento.fromJson).toList();
  }

  @override
  Future<Evento> buscarPorId(String id) async =>
      _evento(await apiClient.buscarPorId(id));

  @override
  Future<Evento> criar(DadosEvento dados) async =>
      _evento(await apiClient.criar(dados.toJson()));

  @override
  Future<Evento> editar(String id, DadosEvento dados) async =>
      _evento(await apiClient.editar(id, dados.toJson()));

  @override
  Future<void> excluir(String id) => apiClient.excluir(id);

  Evento _evento(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const EventosServidorException();
    }
    return Evento.fromJson(data);
  }
}
