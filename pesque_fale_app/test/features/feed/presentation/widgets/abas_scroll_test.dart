import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:pesque_fale_app/core/data/paged_result.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository_mock.dart';
import 'package:pesque_fale_app/features/auth/data/token_storage.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/feed/data/curtidas_repository.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_repository.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/aba_feed.dart';
import 'package:pesque_fale_app/features/feed/domain/evento.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/presentation/widgets/abas_scroll.dart';
import 'package:pesque_fale_app/features/feed/providers/feed_provider.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_repository.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/filtros_locais.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/ponto.dart';

// Fakes no mesmo padrão de feed_page_test.dart. O AbasScroll só lê a aba
// ativa do FeedProvider, então nenhum deles precisa devolver dados.

class _FakePublicacoesRepository implements PublicacoesRepository {
  @override
  Future<PagedResult<Publicacao>> listar({
    int pagina = 1,
    int porPagina = 20,
    bool seguindo = false,
  }) async {
    return PagedResult(
      items: const [],
      total: 0,
      pagina: pagina,
      porPagina: porPagina,
    );
  }

  @override
  Future<Publicacao> buscarPorId(String id) async => throw UnimplementedError();

  @override
  Future<void> deletar(String id) async {}

  @override
  Future<Publicacao> criar({
    String? descricao,
    String? imagemUrl,
    String? localTexto,
    double? avaliacaoNota,
    String? pontoId,
    List<String> tags = const [],
  }) async => throw UnimplementedError();
}

class _FakeCurtidasRepository implements CurtidasRepository {
  @override
  Future<void> curtir(String publicacaoId) async {}

  @override
  Future<void> descurtir(String publicacaoId) async {}
}

class _FakeEventosRepository implements EventosRepository {
  @override
  Future<List<Evento>> listar({bool futuros = true, int limite = 10}) async =>
      const [];
}

class _FakePontosRepository implements PontosRepository {
  @override
  Future<List<Ponto>> buscar({
    required FiltrosLocais filtros,
    double? lat,
    double? lng,
    bool incluirDistancia = false,
    String? ordem,
  }) async => const [];

  @override
  Future<Ponto> buscarPorId(String id) async => throw UnimplementedError();
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montarWidget(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final provider = FeedProvider(
      publicacoesRepo: _FakePublicacoesRepository(),
      curtidasRepo: _FakeCurtidasRepository(),
      eventosRepo: _FakeEventosRepository(),
      pontosRepo: _FakePontosRepository(),
      authProvider: AuthProvider(
        repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<FeedProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: AbasScroll()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('em 360dp as 5 abas existem, com fade e sem overflow', (
    tester,
  ) async {
    await montarWidget(tester);

    expect(tester.takeException(), isNull);
    for (final aba in AbaFeed.values) {
      expect(find.text(aba.label), findsOneWidget);
    }
    expect(
      find.descendant(
        of: find.byType(AbasScroll),
        matching: find.byType(ShaderMask),
      ),
      findsOneWidget,
    );
  });

  testWidgets('no fim da rolagem a ultima aba fica fora da faixa do fade', (
    tester,
  ) async {
    await montarWidget(tester);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-1000, 0),
    );
    await tester.pumpAndSettle();

    final area = tester.getRect(find.byType(AbasScroll));
    final ultimaAba = tester.getRect(
      find.ancestor(
        of: find.text(AbaFeed.values.last.label),
        matching: find.byType(InkWell),
      ),
    );
    expect(ultimaAba.right, lessThanOrEqualTo(area.right - 24));
  });
}
