import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/data/paged_result.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository_mock.dart';
import 'package:pesque_fale_app/features/auth/data/token_storage.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/feed/data/comentarios_repository.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/comentario.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';
import 'package:pesque_fale_app/features/visualizacao_post/presentation/publicacao_detalhe_page.dart';
import 'package:pesque_fale_app/features/visualizacao_post/providers/publicacao_detalhe_provider.dart';

class _FakePublicacoesRepository implements PublicacoesRepository {
  @override
  Future<Publicacao> buscarPorId(String id) => throw UnimplementedError();

  @override
  Future<void> deletar(String id) async {}

  @override
  Future<PagedResult<Publicacao>> listar({
    int pagina = 1,
    int porPagina = 20,
    bool seguindo = false,
  }) => throw UnimplementedError();

  @override
  Future<Publicacao> criar({
    String? descricao,
    String? imagemUrl,
    String? localTexto,
    double? avaliacaoNota,
    String? pontoId,
    List<String> tags = const [],
  }) => throw UnimplementedError();
}

class _FakeComentariosRepository implements ComentariosRepository {
  @override
  Future<PagedResult<Comentario>> listar(
    String publicacaoId, {
    int pagina = 1,
    int porPagina = 20,
  }) async => const PagedResult(items: [], total: 0, pagina: 1, porPagina: 20);

  @override
  Future<Comentario> criar(String publicacaoId, String texto) =>
      throw UnimplementedError();

  @override
  Future<void> deletar(String comentarioId) async {}
}

final _publicacao = Publicacao(
  id: 'p1',
  autorId: 'autor-1',
  autorNome: 'Ana',
  descricao: 'Tilápia no fim da tarde',
  criadoEm: DateTime(2026, 1, 1),
  atualizadoEm: DateTime(2026, 1, 1),
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets(
    'publicação removida em outra tela avisa e volta para a tela anterior',
    (tester) async {
      final store = PublicacoesStore()..upsert(_publicacao);
      final publicacoesRepo = _FakePublicacoesRepository();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(
                repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
              ),
            ),
            ChangeNotifierProvider<PublicacoesStore>.value(value: store),
            Provider<PublicacoesRepository>.value(value: publicacoesRepo),
            Provider<ComentariosRepository>.value(
              value: _FakeComentariosRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ChangeNotifierProvider<PublicacaoDetalheProvider>(
                            create: (ctx) => PublicacaoDetalheProvider(
                              publicacoesRepository: publicacoesRepo,
                              store: store,
                              publicacaoInicial: _publicacao,
                            )..carregar(),
                            child: const PublicacaoDetalhePage(),
                          ),
                    ),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Tilápia no fim da tarde'), findsOneWidget);

      store.remover('p1');
      await tester.pumpAndSettle();

      expect(find.byType(PublicacaoDetalhePage), findsNothing);
      expect(find.text('Abrir'), findsOneWidget);
      expect(find.text('Esta publicação foi excluída.'), findsOneWidget);
    },
  );
}
