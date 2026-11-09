import '../domain/dados_evento.dart';
import '../domain/evento.dart';

abstract class EventosRepository {
  Future<List<Evento>> listar({bool futuros = true, int limite = 10});

  Future<Evento> buscarPorId(String id);

  Future<Evento> criar(DadosEvento dados);

  Future<Evento> editar(String id, DadosEvento dados);

  Future<void> excluir(String id);
}
