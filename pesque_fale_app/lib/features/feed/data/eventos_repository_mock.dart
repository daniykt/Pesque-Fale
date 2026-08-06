import '../domain/evento.dart';
import 'eventos_repository.dart';

class EventosRepositoryMock implements EventosRepository {
  static const _delay = Duration(milliseconds: 400);

  static final DateTime _base = DateTime.now();

  static final List<Evento> _todos = List.generate(6, (i) {
    return Evento(
      id: 'evento-$i',
      titulo: 'Torneio de Pesca ${i + 1}ª Edição',
      descricao:
          'Evento comunitário de pesca esportiva com premiação para os '
          'maiores peixes capturados no dia.',
      organizadorId: 'autor-$i',
      organizadorNome: 'Clube de Pesca ${i + 1}',
      dataInicio: _base.add(Duration(days: i * 5 + 2)),
      dataFim: _base.add(Duration(days: i * 5 + 2, hours: 6)),
      imagemUrl: i.isEven
          ? 'https://picsum.photos/seed/evento-$i/800/320'
          : null,
      localTexto: i.isEven ? 'Represa de Ibitinga, SP' : null,
      criadoEm: _base.subtract(Duration(days: i)),
    );
  });

  @override
  Future<List<Evento>> listar({bool futuros = true, int limite = 10}) async {
    await Future.delayed(_delay);

    var resultado = List<Evento>.of(_todos);
    if (futuros) {
      resultado = resultado
          .where((e) => e.dataInicio.isAfter(DateTime.now()))
          .toList();
    }
    resultado.sort((a, b) => a.dataInicio.compareTo(b.dataInicio));
    return resultado.take(limite).toList();
  }
}
