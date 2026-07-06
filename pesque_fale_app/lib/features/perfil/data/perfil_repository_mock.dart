import 'dart:io';

import '../../auth/domain/usuario.dart';
import '../domain/perfil_completo.dart';
import '../domain/publicacao.dart';
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
  Future<String> atualizarFoto(File arquivo) async {
    await Future.delayed(_delay);
    return 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/200/200';
  }

  @override
  Future<String> atualizarBanner(File arquivo) async {
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
}
