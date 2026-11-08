import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/core/servidor/servidor_status_provider.dart';

import 'support/fake_health.dart';

/// Os testes rodam em testWidgets só pelo relógio falso: `tester.pump`
/// avança timers e timeouts sem espera real.
void main() {
  /// Descarta o provider e deixa vencer os timeouts das tentativas que
  /// ficaram penduradas, para o teste terminar sem timer pendente.
  Future<void> encerrar(
    WidgetTester tester,
    ServidorStatusProvider servidor,
  ) async {
    servidor.dispose();
    await tester.pump(const Duration(seconds: 30));
  }

  testWidgets('iniciar duas vezes faz uma chamada só', (tester) async {
    final health = FakeHealth();
    final servidor = health.criarProvider()..iniciar();
    await tester.pump();

    expect(health.chamadas, 1);
    expect(servidor.status, ServidorStatus.verificando);
    expect(servidor.aviso, AvisoServidor.nenhum);
    await encerrar(tester, servidor);
  });

  testWidgets('resposta antes de 3s: pronto, sem aviso nenhum', (tester) async {
    final health = FakeHealth();
    final servidor = health.criarProvider();
    await tester.pump(const Duration(seconds: 2));
    health.responder();
    await tester.pump();

    expect(servidor.status, ServidorStatus.pronto);
    expect(servidor.aviso, AvisoServidor.nenhum);
    expect(await servidor.aguardarPronto(), isTrue);
    await encerrar(tester, servidor);
  });

  testWidgets('aos 3s vira demorando e o contador conta o tempo decorrido', (
    tester,
  ) async {
    final health = FakeHealth();
    final servidor = health.criarProvider();
    await tester.pump(const Duration(seconds: 2));
    expect(servidor.status, ServidorStatus.verificando);

    await tester.pump(const Duration(seconds: 1));
    expect(servidor.status, ServidorStatus.demorando);
    expect(servidor.aviso, AvisoServidor.conectando);
    expect(servidor.segundosDecorridos, 3);

    await tester.pump(const Duration(seconds: 4));
    expect(servidor.segundosDecorridos, 7);
    await encerrar(tester, servidor);
  });

  testWidgets('pronto depois do aviso mostra "pronto" por 2s e some', (
    tester,
  ) async {
    final health = FakeHealth();
    final servidor = health.criarProvider();
    await tester.pump(const Duration(seconds: 10));
    health.responder();
    await tester.pump();

    expect(servidor.status, ServidorStatus.pronto);
    expect(servidor.aviso, AvisoServidor.pronto);
    await tester.pump(const Duration(milliseconds: 1900));
    expect(servidor.aviso, AvisoServidor.pronto);
    await tester.pump(const Duration(milliseconds: 100));
    expect(servidor.aviso, AvisoServidor.nenhum);
    await encerrar(tester, servidor);
  });

  testWidgets('502 enquanto o Render sobe: tenta de novo e fica pronto', (
    tester,
  ) async {
    final health = FakeHealth();
    final servidor = health.criarProvider();
    await tester.pump(const Duration(seconds: 1));
    health.responder(502);
    await tester.pump();
    expect(servidor.status, ServidorStatus.verificando);

    await tester.pump(const Duration(seconds: 2));
    expect(health.chamadas, 2);
    health.responder();
    await tester.pump();
    expect(servidor.status, ServidorStatus.pronto);
    await encerrar(tester, servidor);
  });

  testWidgets('sem resposta: tenta a cada timeout e falha aos 90s', (
    tester,
  ) async {
    final health = FakeHealth();
    final servidor = health.criarProvider();
    final espera = servidor.aguardarPronto();

    // Timeout de 20s por tentativa + 2s de pausa.
    await tester.pump(const Duration(seconds: 22));
    expect(health.chamadas, 2);

    await tester.pump(const Duration(seconds: 67));
    expect(servidor.status, ServidorStatus.demorando);
    await tester.pump(const Duration(seconds: 1));
    expect(servidor.status, ServidorStatus.falhou);
    expect(servidor.aviso, AvisoServidor.falhou);
    expect(await espera, isFalse);
    expect(await servidor.aguardarPronto(), isFalse);
    await encerrar(tester, servidor);
  });

  testWidgets('tentar de novo zera o contador e checa outra vez', (
    tester,
  ) async {
    final health = FakeHealth();
    final servidor = health.criarProvider();
    await tester.pump(const Duration(seconds: 90));
    expect(servidor.status, ServidorStatus.falhou);
    final chamadasAntes = health.chamadas;

    servidor.tentarDeNovo();
    await tester.pump();
    expect(health.chamadas, chamadasAntes + 1);
    expect(servidor.segundosDecorridos, 0);
    // O aviso já estava na tela: não some nos primeiros 3s.
    expect(servidor.aviso, AvisoServidor.conectando);

    await tester.pump(const Duration(seconds: 1));
    expect(servidor.segundosDecorridos, 1);
    health.responder();
    await tester.pump();
    expect(servidor.status, ServidorStatus.pronto);
    expect(servidor.aviso, AvisoServidor.pronto);
    await encerrar(tester, servidor);
  });

  testWidgets('resposta atrasada de uma checagem antiga é ignorada', (
    tester,
  ) async {
    final health = FakeHealth();
    final servidor = health.criarProvider();
    await tester.pump(const Duration(seconds: 89));
    await tester.pump(const Duration(seconds: 1));
    expect(servidor.status, ServidorStatus.falhou);

    // A última tentativa da checagem que falhou ainda está pendurada.
    health.responder();
    await tester.pump();
    expect(servidor.status, ServidorStatus.falhou);
    await encerrar(tester, servidor);
  });

  testWidgets('mock: nasce pronto, sem cliente e sem aviso', (tester) async {
    final servidor = ServidorStatusProvider.pronto()..iniciar();
    await tester.pump(const Duration(seconds: 10));

    expect(servidor.client, isNull);
    expect(servidor.status, ServidorStatus.pronto);
    expect(servidor.aviso, AvisoServidor.nenhum);
    expect(await servidor.aguardarPronto(), isTrue);
    servidor.dispose();
  });
}
