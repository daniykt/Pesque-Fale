import 'dart:io';

import '../../auth/domain/usuario.dart';
import '../domain/perfil_completo.dart';
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
    final usuario = await apiClient.buscarPerfil(id);
    final publicacoes = await apiClient.buscarPublicacoes(id);

    // O backend ainda não expõe se o usuário logado segue/é seguido por
    // este perfil (gap de contrato — ver issue de continuação da Fase 2).
    // Assumimos "não segue" como padrão seguro até o endpoint existir.
    return PerfilCompleto(
      usuario: usuario,
      publicacoes: publicacoes,
      isFollowing: false,
      seguidoPeloOutro: false,
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
}
