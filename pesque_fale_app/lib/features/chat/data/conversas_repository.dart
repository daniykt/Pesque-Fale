import '../domain/conversa.dart';

abstract class ConversasRepository {
  Future<List<Conversa>> listar();
}
