import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/core/utils/formatador_tempo_relativo.dart';

void main() {
  const formatador = FormatadorTempoRelativo();
  final agora = DateTime(2026, 5, 28, 14, 30);

  group('FormatadorTempoRelativo', () {
    test('menos de 60s retorna "agora"', () {
      expect(
        formatador.formatar(agora.subtract(const Duration(seconds: 30)), agora: agora),
        'agora',
      );
    });

    test('5 min retorna "há 5 min"', () {
      expect(
        formatador.formatar(agora.subtract(const Duration(minutes: 5)), agora: agora),
        'há 5 min',
      );
    });

    test('2h retorna "há 2h"', () {
      expect(
        formatador.formatar(agora.subtract(const Duration(hours: 2)), agora: agora),
        'há 2h',
      );
    });

    test('1 dia retorna singular "há 1 dia"', () {
      expect(
        formatador.formatar(agora.subtract(const Duration(days: 1)), agora: agora),
        'há 1 dia',
      );
    });

    test('3 dias retorna plural "há 3 dias"', () {
      expect(
        formatador.formatar(agora.subtract(const Duration(days: 3)), agora: agora),
        'há 3 dias',
      );
    });

    test('14 dias retorna "há 2 sem"', () {
      expect(
        formatador.formatar(agora.subtract(const Duration(days: 14)), agora: agora),
        'há 2 sem',
      );
    });

    test('60 dias retorna "há 2 meses"', () {
      expect(
        formatador.formatar(agora.subtract(const Duration(days: 60)), agora: agora),
        'há 2 meses',
      );
    });

    test('400 dias retorna "há 1 ano"', () {
      expect(
        formatador.formatar(agora.subtract(const Duration(days: 400)), agora: agora),
        'há 1 ano',
      );
    });
  });
}
