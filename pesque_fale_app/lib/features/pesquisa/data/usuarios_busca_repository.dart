import '../domain/usuario_resumo.dart';

abstract class UsuariosBuscaRepository {
  Future<List<UsuarioResumo>> buscar(String texto);
}
