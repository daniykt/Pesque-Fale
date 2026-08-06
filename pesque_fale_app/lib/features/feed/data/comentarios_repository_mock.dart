import '../../../core/data/paged_result.dart';
import '../domain/comentario.dart';
import 'comentarios_repository.dart';
import 'publicacoes_exceptions.dart';

class ComentariosRepositoryMock implements ComentariosRepository {
  static const _delay = Duration(milliseconds: 300);

  static final DateTime _agora = DateTime(2026, 5, 28, 18, 13, 31);

  final Map<String, List<Comentario>> _porPublicacao = {
    'pub-0': List.generate(
      7,
      (i) => Comentario(
        id: 'pub-0-com-$i',
        publicacaoId: 'pub-0',
        autorId: i == 0 ? 'mock-id' : 'autor-com-$i',
        autorNome: i == 0 ? 'Ana Pescadora' : 'Comentarista $i',
        autorUsername: i == 0 ? 'ana_pesca' : 'comentarista_$i',
        texto: 'Comentário número ${i + 1} sobre essa pescaria!',
        criadoEm: _agora.subtract(Duration(minutes: i * 7)),
      ),
    ),
  };

  int _proximoId = 0;

  @override
  Future<PagedResult<Comentario>> listar(
    String publicacaoId, {
    int pagina = 1,
    int porPagina = 20,
  }) async {
    await Future.delayed(_delay);

    final todos = _porPublicacao[publicacaoId] ?? const [];
    final inicio = (pagina - 1) * porPagina;
    if (inicio >= todos.length) {
      return PagedResult(
        items: const [],
        total: todos.length,
        pagina: pagina,
        porPagina: porPagina,
      );
    }

    final fim = (inicio + porPagina).clamp(0, todos.length);
    return PagedResult(
      items: todos.sublist(inicio, fim),
      total: todos.length,
      pagina: pagina,
      porPagina: porPagina,
    );
  }

  @override
  Future<Comentario> criar(String publicacaoId, String texto) async {
    await Future.delayed(_delay);

    if (texto.isEmpty || texto.length > 500) {
      throw const TextoInvalidoException();
    }

    final comentario = Comentario(
      id: 'mock-com-${_proximoId++}',
      publicacaoId: publicacaoId,
      autorId: 'mock-id',
      autorNome: 'Ana Pescadora',
      autorUsername: 'ana_pesca',
      texto: texto,
      criadoEm: DateTime.now(),
    );

    final lista = _porPublicacao.putIfAbsent(publicacaoId, () => []);
    lista.insert(0, comentario);
    return comentario;
  }

  @override
  Future<void> deletar(String comentarioId) async {
    await Future.delayed(_delay);
    for (final lista in _porPublicacao.values) {
      lista.removeWhere((c) => c.id == comentarioId);
    }
  }
}
