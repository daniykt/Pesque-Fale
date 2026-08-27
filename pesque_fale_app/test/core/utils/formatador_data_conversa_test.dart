import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/core/utils/formatador_data_conversa.dart';

void main() {
  const formatador = FormatadorDataConversa();
  final agora = DateTime(2026, 5, 28, 14, 30); // quinta-feira

  group('FormatadorDataConversa', () {
    test('hoje retorna HH:mm', () {
      expect(
        formatador.formatar(DateTime(2026, 5, 28, 9, 5), agora: agora),
        '09:05',
      );
    });
    test('ontem retorna "Ontem"', () {
      expect(
        formatador.formatar(DateTime(2026, 5, 27, 18, 0), agora: agora),
        'Ontem',
      );
    });
    test('2 dias atrás retorna dia da semana', () {
      // 26/05/2026 é terça
      expect(
        formatador.formatar(DateTime(2026, 5, 26, 10, 0), agora: agora),
        'ter',
      );
    });
    test('6 dias atrás retorna dia da semana', () {
      // 22/05/2026 é sexta
      expect(
        formatador.formatar(DateTime(2026, 5, 22, 10, 0), agora: agora),
        'sex',
      );
    });
    test('7 dias atrás retorna dd/MM', () {
      expect(
        formatador.formatar(DateTime(2026, 5, 21, 10, 0), agora: agora),
        '21/05',
      );
    });
    test('mesmo ano mas mais antigo retorna dd/MM', () {
      expect(
        formatador.formatar(DateTime(2026, 1, 15, 10, 0), agora: agora),
        '15/01',
      );
    });
    test('ano anterior retorna dd/MM/aa', () {
      expect(
        formatador.formatar(DateTime(2024, 12, 25, 10, 0), agora: agora),
        '25/12/24',
      );
    });
  });
}
