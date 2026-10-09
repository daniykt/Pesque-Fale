import 'dart:typed_data';

import '../../auth/domain/usuario.dart';
import '../domain/perfil_completo.dart';
import '../domain/publicacao.dart';
import 'perfil_api_client.dart';
import 'perfil_exceptions.dart';
import 'perfil_repository.dart';

class PerfilRepositoryMock implements PerfilRepository {
  static const _delay = Duration(milliseconds: 800);
  static const _delayUsername = Duration(milliseconds: 400);
  static const _meuId = 'mock-id';

  static const _usuariosIniciais = <String, Usuario>{
    'mock-id': Usuario(
      id: 'mock-id',
      nome: 'Ana Pescadora',
      email: 'ana@teste.com',
      username: 'ana_pesca',
      fotoPerfil: 'https://picsum.photos/seed/ana/200/200',
      banner: 'https://picsum.photos/seed/ana-banner/800/450',
      bio: 'Apaixonada por pesca esportiva e conservação de rios.',
      localizacao: 'Florianópolis, SC',
      onboardingConcluido: true,
      seguidores: 128,
      seguindo: 54,
    ),
    'mock-2': Usuario(
      id: 'mock-2',
      nome: 'Bruno Sem Foto',
      email: 'bruno@teste.com',
      username: 'bruno_sf',
      bio: 'Só comecei agora, mas já fisguei uma tilápia enorme!',
      localizacao: 'Belo Horizonte, MG',
      onboardingConcluido: true,
      seguidores: 12,
      seguindo: 20,
    ),
    'mock-3': Usuario(
      id: 'mock-3',
      nome: 'Carla Vazia',
      email: 'carla@teste.com',
      onboardingConcluido: true,
    ),
  };

  static final _publicacoes = <String, List<Publicacao>>{
    'mock-id': List.generate(
      5,
      (i) => Publicacao(
        id: 'ana-post-$i',
        autorId: 'mock-id',
        imagemUrl: 'https://picsum.photos/seed/ana-post-$i/400/400',
        legenda: 'Pescaria do dia ${i + 1}',
        tags: const ['tilapia', 'rio'],
        curtidasCount: 10 + i,
        comentariosCount: i,
      ),
    ),
    'mock-2': List.generate(
      2,
      (i) => Publicacao(
        id: 'bruno-post-$i',
        autorId: 'mock-2',
        imagemUrl: 'https://picsum.photos/seed/bruno-post-$i/400/400',
        curtidasCount: i,
      ),
    ),
    'mock-3': const [],
  };

  final Map<String, Usuario> _usuarios = Map.of(_usuariosIniciais);
  final _seguindoPorMim = <String>{'mock-2'};

  @override
  Future<PerfilCompleto> buscarPerfil(
    String id, {
    required String meuId,
  }) async {
    await Future.delayed(_delay);

    final usuario = _usuarios[id];
    if (usuario == null) {
      throw const PerfilNaoEncontradoException();
    }

    return PerfilCompleto(
      usuario: usuario,
      publicacoes: _publicacoes[id] ?? const [],
      isFollowing: id != meuId && _seguindoPorMim.contains(id),
      seguidoPeloOutro: false,
    );
  }

  @override
  Future<void> seguir(String id) async {
    await Future.delayed(_delay);
    _seguindoPorMim.add(id);
  }

  @override
  Future<void> deixarDeSeguir(String id) async {
    await Future.delayed(_delay);
    _seguindoPorMim.remove(id);
  }

  @override
  Future<String> atualizarFoto(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async {
    await Future.delayed(_delay);
    return 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/200/200';
  }

  @override
  Future<String> atualizarBanner(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async {
    await Future.delayed(_delay);
    return 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/800/450';
  }

  @override
  Future<Usuario> editarPerfil(Map<String, dynamic> camposAlterados) async {
    await Future.delayed(_delay);

    final atual = _usuarios[_meuId]!;
    final atualizado = atual.copyWith(
      nome: camposAlterados['nome'] as String?,
      bio: camposAlterados['bio'] as String?,
      localizacao: camposAlterados['localizacao'] as String?,
      username: camposAlterados['username'] as String?,
      fotoPerfil: camposAlterados['fotoPerfil'] as String?,
      banner: camposAlterados['banner'] as String?,
    );
    _usuarios[_meuId] = atualizado;
    return atualizado;
  }

  @override
  Future<bool> verificarUsername(String username) async {
    await Future.delayed(_delayUsername);
    if (username == 'existente') return false;
    if (username == 'erro') throw const InternalServerException();
    return true;
  }

  @override
  Future<ListaPaginada<UsuarioResumido>> buscarSeguidores(
    String id, {
    int pagina = 1,
    int porPagina = 20,
  }) async {
    await Future.delayed(_delay);
    final usuario = _usuarios[id];
    if (usuario == null) {
      throw const PerfilNaoEncontradoException();
    }
    return _paginar(
      _gerarListaFake(semente: 'seguidores-$id', total: usuario.seguidores),
      pagina: pagina,
      porPagina: porPagina,
    );
  }

  @override
  Future<ListaPaginada<UsuarioResumido>> buscarSeguindo(
    String id, {
    int pagina = 1,
    int porPagina = 20,
  }) async {
    await Future.delayed(_delay);
    final usuario = _usuarios[id];
    if (usuario == null) {
      throw const PerfilNaoEncontradoException();
    }
    return _paginar(
      _gerarListaFake(semente: 'seguindo-$id', total: usuario.seguindo),
      pagina: pagina,
      porPagina: porPagina,
    );
  }

  /// Gera uma lista determinística de usuários fake pra popular os modais de
  /// seguidores/seguindo. Os três usuários "reais" do mock entram primeiro —
  /// pra permitir follow/unfollow coerente com `_seguindoPorMim` — e o resto
  /// é preenchido com usuários gerados a partir da semente.
  List<UsuarioResumido> _gerarListaFake({
    required String semente,
    required int total,
  }) {
    final itens = <UsuarioResumido>[];
    final reais = _usuarios.values.toList();
    for (var i = 0; i < total; i++) {
      if (i < reais.length) {
        final u = reais[i];
        itens.add(
          UsuarioResumido(
            id: u.id,
            nome: u.nome,
            username: u.username,
            fotoPerfil: u.fotoPerfil,
            souSeguidor: u.id == _meuId ? null : _seguindoPorMim.contains(u.id),
          ),
        );
      } else {
        final idFake = '$semente-$i';
        itens.add(
          UsuarioResumido(
            id: idFake,
            nome: 'Pescador ${i + 1}',
            username: 'pescador_${i + 1}',
            fotoPerfil: 'https://picsum.photos/seed/$idFake/120/120',
            souSeguidor: _seguindoPorMim.contains(idFake),
          ),
        );
      }
    }
    return itens;
  }

  ListaPaginada<UsuarioResumido> _paginar(
    List<UsuarioResumido> itens, {
    required int pagina,
    required int porPagina,
  }) {
    final inicio = (pagina - 1) * porPagina;
    if (inicio >= itens.length) {
      return ListaPaginada(
        itens: const [],
        total: itens.length,
        pagina: pagina,
        porPagina: porPagina,
      );
    }
    final fim = (inicio + porPagina).clamp(0, itens.length);
    return ListaPaginada(
      itens: itens.sublist(inicio, fim),
      total: itens.length,
      pagina: pagina,
      porPagina: porPagina,
    );
  }
}
