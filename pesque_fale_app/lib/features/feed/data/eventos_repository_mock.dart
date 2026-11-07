import '../domain/dados_evento.dart';
import '../domain/evento.dart';
import 'eventos_exceptions.dart';
import 'eventos_repository.dart';

class EventosRepositoryMock implements EventosRepository {
  EventosRepositoryMock({
    DateTime Function()? agora,
    this.atraso = const Duration(milliseconds: 400),
  }) : _agora = agora ?? DateTime.now {
    final base = _agora();
    _todos.addAll(
      List.generate(6, (i) {
        return Evento(
          id: 'evento-$i',
          titulo: 'Torneio de Pesca ${i + 1}ª Edição',
          descricao:
              'Evento comunitário de pesca esportiva com premiação para os '
              'maiores peixes capturados no dia.',
          organizadorId: 'autor-$i',
          organizadorNome: 'Clube de Pesca ${i + 1}',
          dataInicio: base.add(Duration(days: i * 5 + 2)),
          dataFim: base.add(Duration(days: i * 5 + 2, hours: 6)),
          imagemUrl: i.isEven
              ? 'https://picsum.photos/seed/evento-$i/800/320'
              : null,
          localTexto: i.isEven ? 'Represa de Ibitinga, SP' : null,
          criadoEm: base.subtract(Duration(days: i)),
        );
      }),
    );
  }

  final Duration atraso;
  static const _organizadorId = 'mock-id';
  static const _organizadorNome = 'Você';

  final DateTime Function() _agora;
  final List<Evento> _todos = [];
  int _proximoId = 0;

  @override
  Future<List<Evento>> listar({bool futuros = true, int limite = 10}) async {
    await Future.delayed(atraso);

    final agora = _agora();
    final resultado = futuros
        ? _todos
              .where((e) => !(e.dataFim ?? e.dataInicio).isBefore(agora))
              .toList()
        : List<Evento>.of(_todos);
    resultado.sort(
      (a, b) => futuros
          ? a.dataInicio.compareTo(b.dataInicio)
          : b.dataInicio.compareTo(a.dataInicio),
    );
    return resultado.take(limite).toList();
  }

  @override
  Future<Evento> buscarPorId(String id) async {
    await Future.delayed(atraso);
    return _todos[_indice(id)];
  }

  @override
  Future<Evento> criar(DadosEvento dados) async {
    await Future.delayed(atraso);
    _validar(dados);
    final evento = _montar(
      id: 'evento-novo-${_proximoId++}',
      dados: dados,
      organizadorId: _organizadorId,
      organizadorNome: _organizadorNome,
      criadoEm: _agora(),
    );
    _todos.add(evento);
    return evento;
  }

  @override
  Future<Evento> editar(String id, DadosEvento dados) async {
    await Future.delayed(atraso);
    final indice = _indice(id);
    _validar(dados);
    final atual = _todos[indice];
    final evento = _montar(
      id: id,
      dados: dados,
      organizadorId: atual.organizadorId,
      organizadorNome: atual.organizadorNome,
      organizadorUsername: atual.organizadorUsername,
      organizadorFoto: atual.organizadorFoto,
      criadoEm: atual.criadoEm,
    );
    _todos[indice] = evento;
    return evento;
  }

  @override
  Future<void> excluir(String id) async {
    await Future.delayed(atraso);
    _todos.removeAt(_indice(id));
  }

  int _indice(String id) {
    final indice = _todos.indexWhere((e) => e.id == id);
    if (indice < 0) throw const EventoNaoEncontradoException();
    return indice;
  }

  void _validar(DadosEvento dados) {
    final erros = <String, String>{};
    final titulo = dados.titulo.trim();
    if (titulo.length < 2 || dados.titulo.length > 200) {
      erros['titulo'] = 'Título deve ter entre 2 e 200 caracteres.';
    }
    if ((dados.localTexto?.length ?? 0) > 150) {
      erros['localTexto'] = 'Local deve ter no máximo 150 caracteres.';
    }
    final fim = dados.dataFim;
    if (fim != null && fim.isBefore(dados.dataInicio)) {
      erros['dataFim'] =
          'A data de fim deve ser igual ou posterior à data de início.';
    }
    if (erros.isNotEmpty) throw EventoValidacaoException(erros);
  }

  Evento _montar({
    required String id,
    required DadosEvento dados,
    required String organizadorId,
    required String organizadorNome,
    String? organizadorUsername,
    String? organizadorFoto,
    required DateTime criadoEm,
  }) {
    return Evento(
      id: id,
      titulo: dados.titulo,
      descricao: dados.descricao,
      pontoId: dados.pontoId,
      organizadorId: organizadorId,
      organizadorNome: organizadorNome,
      organizadorUsername: organizadorUsername,
      organizadorFoto: organizadorFoto,
      dataInicio: dados.dataInicio,
      dataFim: dados.dataFim,
      imagemUrl: dados.imagemUrl,
      localTexto: dados.localTexto,
      criadoEm: criadoEm,
    );
  }
}
