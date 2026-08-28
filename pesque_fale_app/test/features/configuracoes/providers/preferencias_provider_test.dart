import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/configuracoes/providers/preferencias_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'notificacoesAtivas retorna true por padrao quando SharedPreferences esta vazio',
    () async {
      SharedPreferences.setMockInitialValues({});
      final provider = PreferenciasProvider();
      await Future<void>.delayed(Duration.zero);

      expect(provider.notificacoesAtivas, isTrue);
    },
  );

  test('setNotificacoesAtivas(false) atualiza estado e persiste', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = PreferenciasProvider();
    await Future<void>.delayed(Duration.zero);

    await provider.setNotificacoesAtivas(false);

    expect(provider.notificacoesAtivas, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('preferencias.notificacoes_ativas'), isFalse);
  });

  test('carrega valor persistido do SharedPreferences no construtor', () async {
    SharedPreferences.setMockInitialValues({
      'preferencias.notificacoes_ativas': false,
    });
    final provider = PreferenciasProvider();
    await Future<void>.delayed(Duration.zero);

    expect(provider.notificacoesAtivas, isFalse);
  });

  test('notifyListeners e chamado ao alterar valor', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = PreferenciasProvider();
    await Future<void>.delayed(Duration.zero);

    var chamadas = 0;
    provider.addListener(() => chamadas++);

    await provider.setNotificacoesAtivas(false);

    expect(chamadas, greaterThan(0));
  });
}
