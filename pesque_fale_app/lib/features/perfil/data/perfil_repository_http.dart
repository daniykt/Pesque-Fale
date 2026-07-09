import 'dart:io';

import '../../auth/domain/usuario.dart';
import '../domain/perfil_completo.dart';
import '../domain/publicacao.dart';
import 'perfil_api_client.dart';
import 'perfil_repository.dart';

class PerfilRepositoryHttp implements PerfilRepository {
  PerfilRepositoryHttp({required this.apiClient});

  final PerfilApiClient apiClient;

  @override
  Future<PerfilCompleto> buscarPerfil(
    String id, {
    required String meuId,
  }) async {
    final completo = await apiClient.buscarPerfil(id);
    final paginada = await apiClient.buscarPublicacoes(id);
    return PerfilCompleto(
      usuario: completo.usuario,
      publicacoes: paginada.itens,
      isFollowing: completo.isFollowing,
      seguidoPeloOutro: completo.seguidoPeloOutro,
    );
  }

  @override
  Future<void> seguir(String id) => apiClient.seguir(id);

  @override
  Future<void> deixarDeSeguir(String id) => apiClient.deixarDeSeguir(id);

  @override
  Future<String> atualizarFoto(File arquivo) =>
      apiClient.atualizarFoto(arquivo);

  @override
  Future<String> atualizarBanner(File arquivo) =>
      apiClient.atualizarBanner(arquivo);

  @override
  Future<Usuario> editarPerfil(Map<String, dynamic> camposAlterados) =>
      apiClient.editarPerfil(camposAlterados);

  @override
  Future<bool> verificarUsername(String username) =>
      apiClient.verificarUsername(username);

  Future<ListaPaginada<UsuarioResumido>> buscarSeguidores(
    String id, {
    int pagina = 1,
    int porPagina = 20,
  }) =>
      apiClient.buscarSeguidores(id, pagina: pagina, porPagina: porPagina);

  Future<ListaPaginada<UsuarioResumido>> buscarSeguindo(
    String id, {
    int pagina = 1,
    int porPagina = 20,
  }) =>
      apiClient.buscarSeguindo(id, pagina: pagina, porPagina: porPagina);

  Future<ListaPaginada<Publicacao>> buscarPublicacoesPaginadas(
    String id, {
    int pagina = 1,
    int porPagina = 12,
  }) =>
      apiClient.buscarPublicacoes(id, pagina: pagina, porPagina: porPagina);
}