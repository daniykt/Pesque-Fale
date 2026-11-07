import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/data/paged_result.dart';
import 'package:pesque_fale_app/core/router/rota_detalhe_publicacao.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository_mock.dart';
import 'package:pesque_fale_app/features/auth/data/token_storage.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/feed/data/comentarios_repository.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/comentario.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';
import 'package:pesque_fale_app/features/perfil/presentation/widgets/galeria_perfil.dart';
import 'package:pesque_fale_app/features/visualizacao_post/presentation/publicacao_detalhe_page.dart';
import 'package:pesque_fale_app/features/visualizacao_post/providers/publicacao_detalhe_provider.dart';

/// Conta as idas à API: o detalhe aberto pela galeria não deve buscar nada.
class _FakePublicacoesRepository implements PublicacoesRepository {
  int buscasPorId = 0;

  @override
  Future<Publicacao> buscarPorId(String id) {
    buscasPorId++;
    throw StateError('O detalhe não deveria buscar a publicação na API.');
  }

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

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  final noStore = Publicacao(
    id: 'p1',
    autorId: 'autor-1',
    autorNome: 'Ana Pescadora',
    autorUsername: 'ana_pesca',
    descricao: 'Tilápia no fim da tarde',
    curtidasCount: 4,
    criadoEm: DateTime(2026, 1, 1),
    atualizadoEm: DateTime(2026, 1, 1),
  );

  for (final (nomeTema, criarTema) in [
    ('claro', () => AppTheme.light),
    ('escuro', () => AppTheme.dark),
  ]) {
    testWidgets('detalhe aberto pela galeria mostra o autor do store na hora, '
        'sem buscar na API (tema $nomeTema)', (tester) async {
      final store = PublicacoesStore()..upsert(noStore);
      final publicacoesRepo = _FakePublicacoesRepository();
      // A galeria recebe uma cópia sem o nome do autor (como vinha da API
      // antes da #267). O nome na tela só pode ter vindo do store.
      final naGaleria = noStore.copyWith(autorNome: '');

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
            theme: criarTema(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: GaleriaPerfil(
                  publicacoes: [naGaleria],
                  isOwnProfile: false,
                ),
              ),
            ),
            // A mesma rota do main.dart.
            onGenerateRoute: rotaDetalhePublicacao,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('p1')));
      await tester.pumpAndSettle();

      expect(find.byType(PublicacaoDetalhePage), findsOneWidget);
      expect(find.text('Ana Pescadora'), findsOneWidget);
      expect(find.text('Tilápia no fim da tarde'), findsOneWidget);

      final detalhe = Provider.of<PublicacaoDetalheProvider>(
        tester.element(find.byType(PublicacaoDetalhePage)),
        listen: false,
      );
      expect(detalhe.status, StatusDetalhe.carregado);
      expect(detalhe.publicacao?.id, 'p1');
      expect(publicacoesRepo.buscasPorId, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
