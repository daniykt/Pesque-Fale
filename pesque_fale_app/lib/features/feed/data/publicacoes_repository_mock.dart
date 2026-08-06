import '../../../core/data/paged_result.dart';
import '../domain/publicacao.dart';
import 'publicacoes_exceptions.dart';
import 'publicacoes_repository.dart';

class PublicacoesRepositoryMock implements PublicacoesRepository {
  static const _delay = Duration(milliseconds: 400);

  static final DateTime _agora = DateTime(2026, 5, 28, 18, 13, 31);

  static final List<Publicacao> _todas = List.generate(12, (i) {
    final comFoto = i % 3 != 0;
    final comTags = i % 2 == 0;
    final ehMinha = i == 1;

    return Publicacao(
      id: 'pub-$i',
      autorId: ehMinha ? 'mock-id' : 'autor-$i',
      autorNome: ehMinha ? 'Ana Pescadora' : 'Pescador ${i + 1}',
      autorUsername: ehMinha ? 'ana_pesca' : 'pescador_$i',
      autorFoto: i % 4 == 0
          ? null
          : 'https://picsum.photos/seed/autor-$i/100/100',
      descricao: 'Relato de pescaria número ${i + 1}. Dia incrível na água!',
      imagemUrl: comFoto
          ? 'https://picsum.photos/seed/feed-pub-$i/800/1000'
          : null,
      localTexto: i.isEven ? 'Rio Mogi Guaçu, SP' : null,
      tags: comTags ? const ['tilapia', 'pescaesportiva'] : const [],
      curtidasCount: 5 + i,
      comentariosCount: i,
      jaCurtiu: i % 5 == 0,
      criadoEm: _agora.subtract(Duration(hours: i * 3)),
      atualizadoEm: _agora.subtract(Duration(hours: i * 3)),
    );
  });

  final List<Publicacao> _seguindoIds = _todas.sublist(0, 3);
  final Set<String> _curtidas = _todas
      .where((p) => p.jaCurtiu)
      .map((p) => p.id)
      .toSet();
  final List<String> _deletadas = [];

  @override
  Future<PagedResult<Publicacao>> listar({
    int pagina = 1,
    int porPagina = 20,
    bool seguindo = false,
  }) async {
    await Future.delayed(_delay);

    final origem = seguindo ? _seguindoIds : _todas;
    final disponiveis = origem
        .where((p) => !_deletadas.contains(p.id))
        .map((p) => p.copyWith(jaCurtiu: _curtidas.contains(p.id)))
        .toList();

    final inicio = (pagina - 1) * porPagina;
    if (inicio >= disponiveis.length) {
      return PagedResult(
        items: const [],
        total: disponiveis.length,
        pagina: pagina,
        porPagina: porPagina,
      );
    }

    final fim = (inicio + porPagina).clamp(0, disponiveis.length);
    return PagedResult(
      items: disponiveis.sublist(inicio, fim),
      total: disponiveis.length,
      pagina: pagina,
      porPagina: porPagina,
    );
  }

  @override
  Future<Publicacao> buscarPorId(String id) async {
    await Future.delayed(_delay);
    for (final p in _todas) {
      if (p.id == id && !_deletadas.contains(id)) {
        return p.copyWith(jaCurtiu: _curtidas.contains(p.id));
      }
    }
    throw const PublicacaoNaoEncontradaException();
  }

  @override
  Future<void> deletar(String id) async {
    await Future.delayed(_delay);
    _deletadas.add(id);
  }
}
