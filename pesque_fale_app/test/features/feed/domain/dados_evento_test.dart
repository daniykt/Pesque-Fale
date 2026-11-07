import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/feed/domain/dados_evento.dart';

void main() {
  test('envia as datas em ISO-8601 UTC, terminando em Z', () {
    final inicioLocal = DateTime(2026, 11, 20, 8);
    final dados = DadosEvento(
      titulo: 'Torneio',
      dataInicio: inicioLocal,
      dataFim: inicioLocal.add(const Duration(hours: 4)),
    );

    final json = dados.toJson();

    expect(json['dataInicio'], inicioLocal.toUtc().toIso8601String());
    expect(json['dataInicio'], endsWith('Z'));
    expect(
      DateTime.parse(
        json['dataInicio'] as String,
      ).isAtSameMomentAs(inicioLocal),
      isTrue,
    );
    expect(json['dataFim'], endsWith('Z'));
  });

  test('sem fim, manda dataFim null para o PATCH poder remover', () {
    final json = DadosEvento(
      titulo: 'Torneio',
      dataInicio: DateTime.utc(2026, 11, 20, 11),
    ).toJson();

    expect(json.containsKey('dataFim'), isTrue);
    expect(json['dataFim'], isNull);
    expect(json['dataInicio'], '2026-11-20T11:00:00.000Z');
  });
}
