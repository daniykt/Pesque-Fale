import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/feed/domain/dicas_de_pesca.dart';

void main() {
  test('tem 30 dicas, todas preenchidas e diferentes', () {
    expect(dicasDePesca, hasLength(30));
    expect(dicasDePesca.every((d) => d.trim().length > 20), isTrue);
    expect(dicasDePesca.toSet(), hasLength(dicasDePesca.length));
  });

  test('a dica antiga, que afirmava algo sem dado, não está mais na lista', () {
    expect(
      dicasDePesca.any((d) => d.contains('Tucunaré ataca melhor')),
      isFalse,
    );
  });

  test('1º de janeiro mostra a primeira dica', () {
    expect(dicaDoDia(DateTime(2026, 1, 1)), dicasDePesca.first);
  });

  test('o mesmo dia mostra sempre a mesma dica, em qualquer horário', () {
    expect(
      dicaDoDia(DateTime(2026, 11, 6, 0, 1)),
      dicaDoDia(DateTime(2026, 11, 6, 23, 59)),
    );
  });

  test('dias seguidos mostram dicas diferentes, em ordem', () {
    for (var dia = 1; dia < 30; dia++) {
      expect(
        dicaDoDia(DateTime(2026, 1, dia + 1)),
        dicasDePesca[dia],
        reason: 'dia $dia de janeiro',
      );
    }
  });

  test('a lista recomeça depois de 30 dias', () {
    expect(dicaDoDia(DateTime(2026, 1, 31)), dicasDePesca.first);
  });

  test('dias de março seguem a contagem do ano, inclusive em ano bissexto', () {
    expect(dicaDoDia(DateTime(2026, 3, 1)), dicasDePesca[59 % 30]);
    expect(dicaDoDia(DateTime(2028, 3, 1)), dicasDePesca[60 % 30]);
  });

  test('o fim e o começo do ano não quebram', () {
    expect(dicaDoDia(DateTime(2026, 12, 31)), dicasDePesca[364 % 30]);
    expect(dicaDoDia(DateTime(2027, 1, 1)), dicasDePesca.first);
  });
}
