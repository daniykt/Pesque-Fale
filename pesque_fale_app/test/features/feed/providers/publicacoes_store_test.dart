import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';

Publicacao _pub(
  String id, {
  int curtidas = 0,
  int comentarios = 0,
  bool jaCurtiu = false,
  String? descricao,
  String autorId = 'autor-1',
}) {
  final data = DateTime(2026, 11, 1);
  return Publicacao(
    id: id,
    autorId: autorId,
    autorNome: 'Autor',
    descricao: descricao,
    curtidasCount: curtidas,
    comentariosCount: comentarios,
    jaCurtiu: jaCurtiu,
    criadoEm: data,
    atualizadoEm: data,
  );
}

void main() {
  late PublicacoesStore store;
  late int notificacoes;

  setUp(() {
    store = PublicacoesStore();
    notificacoes = 0;
    store.addListener(() => notificacoes++);
  });

  group('upsert', () {
    test('insere publicação nova e notifica', () {
      store.upsert(_pub('1'));

      expect(store.porId('1'), isNotNull);
      expect(notificacoes, 1);
    });

    test('não notifica quando a publicação é igual', () {
      store.upsert(_pub('1'));
      store.upsert(_pub('1'));

      expect(notificacoes, 1);
    });

    test('substitui e notifica quando algo muda', () {
      store.upsert(_pub('1', descricao: 'antes'));
      store.upsert(_pub('1', descricao: 'depois'));

      expect(store.porId('1')!.descricao, 'depois');
      expect(notificacoes, 2);
    });

    test('ignora publicação já removida', () {
      store.upsert(_pub('1'));
      store.remover('1');
      store.upsert(_pub('1'));

      expect(store.porId('1'), isNull);
      expect(notificacoes, 2);
    });
  });

  group('upsertTodos', () {
    test('insere todas e notifica uma vez só', () {
      store.upsertTodos([_pub('1'), _pub('2'), _pub('3')]);

      expect(store.resolver(['1', '2', '3']), hasLength(3));
      expect(notificacoes, 1);
    });

    test('não notifica quando nada muda', () {
      store.upsertTodos([_pub('1'), _pub('2')]);
      store.upsertTodos([_pub('1'), _pub('2')]);

      expect(notificacoes, 1);
    });
  });

  group('remover', () {
    test('tira do store, marca como removida e notifica', () {
      store.upsert(_pub('1'));
      store.remover('1');

      expect(store.porId('1'), isNull);
      expect(store.foiRemovida('1'), isTrue);
      expect(notificacoes, 2);
    });

    test('remover duas vezes notifica só na primeira', () {
      store.upsert(_pub('1'));
      store.remover('1');
      store.remover('1');

      expect(notificacoes, 2);
    });
  });

  group('resolver', () {
    test('mantém a ordem e pula ids que não existem', () {
      store.upsertTodos([_pub('1'), _pub('2'), _pub('3')]);
      store.remover('2');

      final ids = store.resolver(['3', '2', '1', 'x']).map((p) => p.id);

      expect(ids, ['3', '1']);
    });
  });

  group('atualizarCurtida', () {
    test('muda só a publicação alvo', () {
      store.upsertTodos([_pub('1'), _pub('2')]);
      store.atualizarCurtida('1', jaCurtiu: true, curtidasCount: 1);

      expect(store.porId('1')!.jaCurtiu, isTrue);
      expect(store.porId('1')!.curtidasCount, 1);
      expect(store.porId('2')!.jaCurtiu, isFalse);
      expect(notificacoes, 2);
    });

    test('não notifica quando o valor é o mesmo', () {
      store.upsert(_pub('1', curtidas: 3, jaCurtiu: true));
      store.atualizarCurtida('1', jaCurtiu: true, curtidasCount: 3);

      expect(notificacoes, 1);
    });

    test('ignora id desconhecido', () {
      store.atualizarCurtida('x', jaCurtiu: true, curtidasCount: 1);

      expect(notificacoes, 0);
    });
  });

  group('atualizarComentarios', () {
    test('troca pelo total recebido', () {
      store.upsert(_pub('1', comentarios: 2));
      store.atualizarComentarios('1', 5);

      expect(store.porId('1')!.comentariosCount, 5);
      expect(notificacoes, 2);
    });

    test('não notifica quando o total é o mesmo', () {
      store.upsert(_pub('1', comentarios: 2));
      store.atualizarComentarios('1', 2);

      expect(notificacoes, 1);
    });
  });

  group('inserirSeAusente', () {
    test('insere só as ausentes e notifica uma vez', () {
      store.upsert(_pub('1', jaCurtiu: true, curtidas: 4));
      notificacoes = 0;

      store.inserirSeAusente([_pub('1'), _pub('2'), _pub('3')]);

      expect(store.porId('1')!.jaCurtiu, isTrue);
      expect(store.porId('1')!.curtidasCount, 4);
      expect(store.porId('2'), isNotNull);
      expect(store.porId('3'), isNotNull);
      expect(notificacoes, 1);
    });

    test('ignora removidas', () {
      store.remover('1');
      notificacoes = 0;

      store.inserirSeAusente([_pub('1')]);

      expect(store.porId('1'), isNull);
      expect(notificacoes, 0);
    });

    test('não notifica quando todas já existem', () {
      store.upsert(_pub('1'));
      notificacoes = 0;

      store.inserirSeAusente([_pub('1', curtidas: 9)]);

      expect(store.porId('1')!.curtidasCount, 0);
      expect(notificacoes, 0);
    });
  });

  group('publicacoesDoAutor', () {
    test('devolve só as publicações do autor', () {
      store.upsertTodos([
        _pub('1', autorId: 'ana'),
        _pub('2', autorId: 'bruno'),
        _pub('3', autorId: 'ana'),
      ]);

      expect(store.publicacoesDoAutor('ana').map((p) => p.id), ['1', '3']);
    });
  });

  group('limpar', () {
    test('esvazia publicações e removidas', () {
      store.upsert(_pub('1'));
      store.remover('2');
      store.limpar();

      expect(store.porId('1'), isNull);
      expect(store.foiRemovida('2'), isFalse);
    });

    test('não notifica quando já está vazio', () {
      store.limpar();

      expect(notificacoes, 0);
    });
  });
}
