import '../domain/evento.dart';

abstract class EventosRepository {
  Future<List<Evento>> listar({bool futuros = true, int limite = 10});
}
