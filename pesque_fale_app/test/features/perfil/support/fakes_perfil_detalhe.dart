// Fakes mínimos para testar perfil, feed e detalhe ligados pelo mesmo
// PublicacoesStore (#270). Implementam os repositórios abstratos e guardam
// só o que os testes precisam conferir.
import 'dart:typed_data';

import 'package:pesque_fale_app/core/data/paged_result.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/feed/data/comentarios_repository.dart';
import 'package:pesque_fale_app/features/feed/data/curtidas_repository.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_repository.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/comentario.dart';
import 'package:pesque_fale_app/features/feed/domain/dados_evento.dart';
import 'package:pesque_fale_app/features/feed/domain/evento.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/providers/feed_provider.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_api_client.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository.dart';
import 'package:pesque_fale_app/features/perfil/domain/perfil_completo.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_repository.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/filtros_locais.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/ponto.dart';

import '../../chat/support/fake_realtime_manager.dart';

/// Id do usuário logado e dono do perfil próprio.
const idEu = 'eu';

const usuarioEu = Usuario(
  id: idEu,
  nome: 'Ana Pescadora',
  email: 'ana@teste.com',
  onboardingConcluido: true,
);

Publicacao publicacaoDoEu(
  String id, {
  int dia = 1,
  String? descricao,
  int curtidasCount = 0,
  int comentariosCount = 0,
  bool jaCurtiu = false,
}) => Publicacao(
  id: id,
  autorId: idEu,
  autorNome: usuarioEu.nome,
  descricao: descricao,
  curtidasCount: curtidasCount,
  comentariosCount: comentariosCount,
  jaCurtiu: jaCurtiu,
  criadoEm: DateTime(2026, 1, dia),
  atualizadoEm: DateTime(2026, 1, dia),
);

class FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) async => throw UnimplementedError();

  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async => const AuthResult(accessToken: 'token', usuario: usuarioEu);

  @override
  Future<void> logout() async {}
}

Future<AuthProvider> authLogado() async {
  final auth = AuthProvider(repository: FakeAuthRepository());
  await auth.login(email: usuarioEu.email, senha: '123456');
  return auth;
}

/// Perfil próprio com as publicações da primeira página. Conta as cargas
/// para provar que nada foi recarregado.
class FakePerfilRepository implements PerfilRepository {
  FakePerfilRepository({required this.publicacoes, this.totalPublicacoes});

  final List<Publicacao> publicacoes;
  final int? totalPublicacoes;
  int cargas = 0;

  @override
  Future<PerfilCompleto> buscarPerfil(
    String id, {
    required String meuId,
  }) async {
    cargas++;
    return PerfilCompleto(
      usuario: usuarioEu,
      publicacoes: List.of(publicacoes),
      totalPublicacoes: totalPublicacoes,
    );
  }

  @override
  Future<void> seguir(String id) async => throw UnimplementedError();

  @override
  Future<void> deixarDeSeguir(String id) async => throw UnimplementedError();

  @override
  Future<String> atualizarFoto(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async => throw UnimplementedError();

  @override
  Future<String> atualizarBanner(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async => throw UnimplementedError();

  @override
  Future<Usuario> editarPerfil(Map<String, dynamic> camposAlterados) async =>
      throw UnimplementedError();

  @override
  Future<bool> verificarUsername(String username) async => true;

  @override
  Future<ListaPaginada<UsuarioResumido>> buscarSeguidores(
    String id, {
    int pagina = 1,
    int porPagina = 20,
  }) async => throw UnimplementedError();

  @override
  Future<ListaPaginada<UsuarioResumido>> buscarSeguindo(
    String id, {
    int pagina = 1,
    int porPagina = 20,
  }) async => throw UnimplementedError();
}

/// Feed com as publicações dadas. O detalhe aberto pela galeria não deve
/// buscar por id, então [buscarPorId] conta e falha.
class FakePublicacoesRepository implements PublicacoesRepository {
  FakePublicacoesRepository({required this.feed});

  final List<Publicacao> feed;
  final List<String> deletadas = [];
  int buscasPorId = 0;

  @override
  Future<PagedResult<Publicacao>> listar({
    int pagina = 1,
    int porPagina = 20,
    bool seguindo = false,
  }) async => PagedResult(
    items: pagina == 1 ? List.of(feed) : const [],
    total: feed.length,
    pagina: pagina,
    porPagina: porPagina,
  );

  @override
  Future<Publicacao> buscarPorId(String id) {
    buscasPorId++;
    throw StateError('O detalhe não deveria buscar a publicação na API.');
  }

  @override
  Future<void> deletar(String id) async => deletadas.add(id);

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

class FakeCurtidasRepository implements CurtidasRepository {
  final List<String> curtidas = [];
  final List<String> descurtidas = [];

  @override
  Future<void> curtir(String publicacaoId) async => curtidas.add(publicacaoId);

  @override
  Future<void> descurtir(String publicacaoId) async =>
      descurtidas.add(publicacaoId);
}

class FakeComentariosRepository implements ComentariosRepository {
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

class _FakeEventosRepository implements EventosRepository {
  @override
  Future<List<Evento>> listar({bool futuros = true, int limite = 10}) async =>
      const [];

  @override
  Future<Evento> buscarPorId(String id) => throw UnimplementedError();

  @override
  Future<Evento> criar(DadosEvento dados) => throw UnimplementedError();

  @override
  Future<Evento> editar(String id, DadosEvento dados) =>
      throw UnimplementedError();

  @override
  Future<void> excluir(String id) => throw UnimplementedError();
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
  Future<Ponto> buscarPorId(String id) => throw UnimplementedError();
}

FeedProvider criarFeedProvider({
  required FakePublicacoesRepository publicacoesRepo,
  required FakeCurtidasRepository curtidasRepo,
  required AuthProvider authProvider,
  required PublicacoesStore store,
}) => FeedProvider(
  publicacoesRepo: publicacoesRepo,
  curtidasRepo: curtidasRepo,
  eventosRepo: _FakeEventosRepository(),
  pontosRepo: _FakePontosRepository(),
  authProvider: authProvider,
  realtime: FakeRealtimeManager(),
  store: store,
);
