import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/assistente/domain/mensagem_assistente.dart';
import 'package:pesque_fale_app/features/assistente/providers/voz_provider.dart';

import '../support/fake_servico_voz.dart';

MensagemAssistente _resposta(String texto) =>
    MensagemAssistente(autor: AutorMensagem.assistente, texto: texto);

void main() {
  late FakeServicoVoz servico;
  late VozProvider voz;

  setUp(() {
    servico = FakeServicoVoz();
    voz = VozProvider(servico: servico);
  });

  group('escuta', () {
    test('começa a ouvir e repassa o texto reconhecido', () async {
      final textos = <String>[];

      await voz.alternarEscuta(textos.add);
      expect(voz.ouvindo, isTrue);

      servico.onTexto!('Como publico');
      servico.onTexto!('Como publico uma pescaria');
      expect(textos, ['Como publico', 'Como publico uma pescaria']);

      servico.terminarEscuta();
      expect(voz.ouvindo, isFalse);
    });

    test('tocar de novo para de ouvir', () async {
      await voz.alternarEscuta((_) {});
      await voz.alternarEscuta((_) {});

      expect(voz.ouvindo, isFalse);
      expect(servico.paradasEscuta, 1);
    });

    test('mostra aviso quando o microfone não pode ser usado', () async {
      servico.microfoneLiberado = false;

      await voz.alternarEscuta((_) {});

      expect(voz.ouvindo, isFalse);
      expect(voz.aviso, VozProvider.avisoMicrofone);
    });

    test('começar a ouvir para a leitura em andamento', () async {
      final mensagem = _resposta('Olá!');
      await voz.alternarLeitura(mensagem);

      await voz.alternarEscuta((_) {});

      expect(voz.estaLendo(mensagem), isFalse);
      expect(voz.ouvindo, isTrue);
    });
  });

  group('leitura', () {
    test('lê a resposta sem os símbolos de formatação', () async {
      final mensagem = _resposta('**Olá**, pescador! Use o `#mapa`.');

      await voz.alternarLeitura(mensagem);

      expect(servico.lidos, ['Olá, pescador! Use o mapa.']);
      expect(voz.estaLendo(mensagem), isTrue);

      servico.terminarLeitura();
      expect(voz.estaLendo(mensagem), isFalse);
    });

    test('tocar de novo na mesma resposta para a leitura', () async {
      final mensagem = _resposta('Olá!');

      await voz.alternarLeitura(mensagem);
      await voz.alternarLeitura(mensagem);

      expect(voz.estaLendo(mensagem), isFalse);
      expect(servico.lidos, hasLength(1));
    });

    test('tocar em outra resposta troca a leitura', () async {
      final primeira = _resposta('Primeira');
      final segunda = _resposta('Segunda');

      await voz.alternarLeitura(primeira);
      await voz.alternarLeitura(segunda);

      expect(voz.estaLendo(primeira), isFalse);
      expect(voz.estaLendo(segunda), isTrue);
      expect(servico.lidos, ['Primeira', 'Segunda']);
    });

    test('mostra aviso quando não consegue ler', () async {
      servico.leituraFunciona = false;
      final mensagem = _resposta('Olá!');

      await voz.alternarLeitura(mensagem);

      expect(voz.estaLendo(mensagem), isFalse);
      expect(voz.aviso, VozProvider.avisoLeitura);
    });
  });

  test('ao sair da tela para de ouvir e de ler', () async {
    voz.dispose();

    expect(servico.paradasEscuta, 1);
    expect(servico.paradasLeitura, 1);
  });
}