import '../domain/avaliacao.dart';
import '../domain/criar_editar_avaliacao_input.dart';
import 'avaliacoes_exceptions.dart';
import 'avaliacoes_repository.dart';

class AvaliacoesRepositoryMock implements AvaliacoesRepository {
  static const _delay = Duration(milliseconds: 400);
  static const _meuId = 'mock-id';

  static final DateTime _agora = DateTime.now();

  static final Map<String, List<Avaliacao>> _seed = {
    '1': [
      Avaliacao(
        id: 'av-1',
        usuarioId: 'mock-2',
        usuarioNome: 'Bruno Sem Foto',
        usuarioUsername: 'bruno_sf',
        pontoId: '1',
        nota: 5,
        comentario: 'Excelente lugar, peguei 3 tucunarés em uma manhã!',
        criadoEm: _agora.subtract(const Duration(days: 2)),
        atualizadoEm: _agora.subtract(const Duration(days: 2)),
      ),
      Avaliacao(
        id: 'av-2',
        usuarioId: 'mock-3',
        usuarioNome: 'Carla Vazia',
        usuarioUsername: 'carla_v',
        pontoId: '1',
        nota: 4,
        comentario: 'Água limpa e fácil acesso, recomendo.',
        criadoEm: _agora.subtract(const Duration(days: 10)),
        atualizadoEm: _agora.subtract(const Duration(days: 10)),
      ),
    ],
  };

  final Map<String, List<Avaliacao>> _avaliacoes = {
    for (final entry in _seed.entries) entry.key: List.of(entry.value),
  };

  @override
  Future<List<Avaliacao>> listar(
    String pontoId, {
    int pagina = 1,
    int porPagina = 20,
  }) async {
    await Future.delayed(_delay);

    final lista = List.of(_avaliacoes[pontoId] ?? const <Avaliacao>[])
      ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));

    final inicio = (pagina - 1) * porPagina;
    if (inicio >= lista.length) return const [];
    final fim = (inicio + porPagina).clamp(0, lista.length);
    return lista.sublist(inicio, fim);
  }

  @override
  Future<Avaliacao?> minhaAvaliacao(String pontoId) async {
    await Future.delayed(_delay);
    final lista = _avaliacoes[pontoId] ?? const [];
    for (final a in lista) {
      if (a.usuarioId == _meuId) return a;
    }
    return null;
  }

  @override
  Future<Avaliacao> criar(
    String pontoId,
    CriarEditarAvaliacaoInput input,
  ) async {
    await Future.delayed(_delay);
    final lista = _avaliacoes.putIfAbsent(pontoId, () => []);

    if (lista.any((a) => a.usuarioId == _meuId)) {
      throw const JaAvaliouException();
    }

    final agora = DateTime.now();
    final nova = Avaliacao(
      id: 'av-${agora.millisecondsSinceEpoch}',
      usuarioId: _meuId,
      usuarioNome: 'Usuário Mock',
      usuarioUsername: 'usuario_mock',
      pontoId: pontoId,
      nota: input.nota,
      comentario: input.comentario,
      criadoEm: agora,
      atualizadoEm: agora,
    );
    lista.add(nova);
    return nova;
  }

  @override
  Future<Avaliacao> editar(
    String pontoId,
    CriarEditarAvaliacaoInput input,
  ) async {
    await Future.delayed(_delay);
    final lista = _avaliacoes[pontoId] ?? const [];
    final indice = lista.indexWhere((a) => a.usuarioId == _meuId);
    if (indice == -1) {
      throw const AvaliacaoNaoEncontradaException();
    }

    final existente = lista[indice];
    final editada = Avaliacao(
      id: existente.id,
      usuarioId: existente.usuarioId,
      usuarioNome: existente.usuarioNome,
      usuarioUsername: existente.usuarioUsername,
      usuarioFoto: existente.usuarioFoto,
      pontoId: existente.pontoId,
      nota: input.nota,
      comentario: input.comentario,
      criadoEm: existente.criadoEm,
      atualizadoEm: DateTime.now(),
    );
    _avaliacoes[pontoId]![indice] = editada;
    return editada;
  }

  @override
  Future<void> deletar(String pontoId) async {
    await Future.delayed(_delay);
    final lista = _avaliacoes[pontoId] ?? const [];
    final indice = lista.indexWhere((a) => a.usuarioId == _meuId);
    if (indice == -1) {
      throw const AvaliacaoNaoEncontradaException();
    }
    _avaliacoes[pontoId]!.removeAt(indice);
  }
}
