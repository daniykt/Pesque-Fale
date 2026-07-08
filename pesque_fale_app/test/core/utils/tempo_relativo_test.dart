import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/core/utils/tempo_relativo.dart';

void main() {
  final agora = DateTime(2026, 7, 8, 12, 0, 0);

  String formatar(Duration atras) =>
      TempoRelativo.formatar(agora.subtract(atras), agora: agora);

  test('59 segundos atras retorna agora', () {
    expect(formatar(const Duration(seconds: 59)), 'agora');
  });

  test('1 minuto atras retorna ha 1 min', () {
    expect(formatar(const Duration(minutes: 1)), 'há 1 min');
  });

  test('59 minutos atras retorna ha 59 min', () {
    expect(formatar(const Duration(minutes: 59)), 'há 59 min');
  });

  test('1 hora atras retorna ha 1 h', () {
    expect(formatar(const Duration(hours: 1)), 'há 1 h');
  });

  test('23 horas atras retorna ha 23 h', () {
    expect(formatar(const Duration(hours: 23)), 'há 23 h');
  });

  test('6 dias atras retorna ha 6 dias', () {
    expect(formatar(const Duration(days: 6)), 'há 6 dias');
  });

  test('7 dias atras retorna ha 1 semanas', () {
    expect(formatar(const Duration(days: 7)), 'há 1 semanas');
  });

  test('29 dias atras retorna ha 4 semanas', () {
    expect(formatar(const Duration(days: 29)), 'há 4 semanas');
  });

  test('30 dias atras retorna data absoluta', () {
    final data = agora.subtract(const Duration(days: 30));
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    expect(formatar(const Duration(days: 30)), '$dia/$mes/${data.year}');
  });

  test('60 dias atras retorna data absoluta', () {
    final data = agora.subtract(const Duration(days: 60));
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    expect(formatar(const Duration(days: 60)), '$dia/$mes/${data.year}');
  });
}
