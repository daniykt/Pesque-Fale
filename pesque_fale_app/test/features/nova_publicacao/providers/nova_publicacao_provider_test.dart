import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/core/data/paged_result.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/feed/data/curtidas_repository.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_repository.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_repository.dart';
import 'package:pesque_fale_app/features/feed/data/upload_publicacao_imagem_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/dados_evento.dart';
import 'package:pesque_fale_app/features/feed/domain/evento.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/providers/feed_provider.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';
import 'package:pesque_fale_app/features/nova_publicacao/providers/nova_publicacao_provider.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_repository.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/filtros_locais.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/ponto.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/tipo_ponto.dart';

import '../../chat/support/fake_realtime_manager.dart';

const _usuario = Usuario(
  id: 'ana',
  nome: 'Ana Pescadora',
  email: 'ana@teste.com',
  username: 'ana_pesca',
  fotoPerfil: 'https://res.cloudinary.com/demo/image/upload/ana.jpg',
  onboardingConcluido: true,
);

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) => throw UnimplementedError();

  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async => const AuthResult(accessToken: 'token', usuario: _usuario);

  @override
  Future<void> logout() async {}
}

class _FakePublicacoesRepository implements PublicacoesRepository {
  _FakePublicacoesRepository({required this.resposta});

  final Publicacao resposta;

  @override
  Future<Publicacao> criar({
    String? descricao,
    String? imagemUrl,
    String? localTexto,
    double? avaliacaoNota,
    String? pontoId,
    List<String> tags = const [],
  }) async => resposta;

  @override
  Future<PagedResult<Publicacao>> listar({
    int pagina = 1,
    int porPagina = 20,
    bool seguindo = false,
  }) async => const PagedResult(items: [], total: 0, pagina: 1, porPagina: 20);

  @override
  Future<Publicacao> buscarPorId(String id) => throw UnimplementedError();

  @override
  Future<void> deletar(String id) async {}
}

class _FakeUploadRepository implements UploadPublicacaoImagemRepository {
  @override
  Future<String> upload(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async => 'https://res.cloudinary.com/demo/image/upload/post.jpg';
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

const _ponto = Ponto(
  id: 'ponto-1',
  nome: 'Rio das Pratas',
  latitude: -21.6,
  longitude: -48.3,
  cidade: 'Matão',
  estado: 'SP',
  tipo: TipoPonto.rio,
  criadoPor: 'conta-oficial',
);

Publicacao _respostaDaApi({
  String autorNome = '',
  String? autorUsername,
  String? autorFoto,
}) => Publicacao(
  id: 'nova',
  autorId: 'ana',
  autorNome: autorNome,
  autorUsername: autorUsername,
  autorFoto: autorFoto,
  imagemUrl: 'https://res.cloudinary.com/demo/image/upload/post.jpg',
  criadoEm: DateTime(2026, 11, 5),
  atualizadoEm: DateTime(2026, 11, 5),
);

void main() {
  late AuthProvider authProvider;
  late PublicacoesStore store;
  late FeedProvider feed;

  setUp(() async {
    authProvider = AuthProvider(repository: _FakeAuthRepository());
    await authProvider.login(email: 'ana@teste.com', senha: '123456');
    store = PublicacoesStore();
  });

  Future<Publicacao?> publicar(Publicacao resposta) {
    final publicacoesRepo = _FakePublicacoesRepository(resposta: resposta);
    feed = FeedProvider(
      publicacoesRepo: publicacoesRepo,
      curtidasRepo: _FakeCurtidasRepository(),
      eventosRepo: _FakeEventosRepository(),
      pontosRepo: _FakePontosRepository(),
      authProvider: authProvider,
      realtime: FakeRealtimeManager(),
      store: store,
    );
    final provider =
        NovaPublicacaoProvider(
            publicacoesRepository: publicacoesRepo,
            uploadRepository: _FakeUploadRepository(),
            feedProvider: feed,
            authProvider: authProvider,
          )
          ..setFoto(
            bytes: Uint8List.fromList([1, 2, 3]),
            filename: 'foto.jpg',
            mimeType: 'image/jpeg',
          )
          ..setPonto(_ponto);
    return provider.publicar();
  }

  test(
    'resposta da API sem autor ganha o nome e a foto do usuário logado',
    () async {
      final devolvida = await publicar(_respostaDaApi());

      final noStore = store.porId('nova')!;
      expect(noStore.autorNome, 'Ana Pescadora');
      expect(noStore.autorUsername, 'ana_pesca');
      expect(noStore.autorFoto, _usuario.fotoPerfil);
      expect(feed.paraVoce.first.autorNome, 'Ana Pescadora');
      expect(feed.paraVoce.first.autorFoto, _usuario.fotoPerfil);
      expect(devolvida!.autorNome, 'Ana Pescadora');
    },
  );

  test('autor que já vem da API é mantido', () async {
    await publicar(
      _respostaDaApi(
        autorNome: 'Nome da API',
        autorUsername: 'user_api',
        autorFoto: 'https://res.cloudinary.com/demo/image/upload/api.jpg',
      ),
    );

    final noStore = store.porId('nova')!;
    expect(noStore.autorNome, 'Nome da API');
    expect(noStore.autorUsername, 'user_api');
    expect(
      noStore.autorFoto,
      'https://res.cloudinary.com/demo/image/upload/api.jpg',
    );
  });
}
