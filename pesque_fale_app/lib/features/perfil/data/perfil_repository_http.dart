import 'dart:async';
import 'dart:typed_data';

import '../../auth/domain/usuario.dart';
import '../domain/perfil_completo.dart';
import '../../feed/domain/publicacao.dart';
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
    // As duas requisições saem juntas. O await fica em ordem para manter a
    // prioridade de erro: se o perfil falhar, a exceção é a do perfil.
    // Future.wait mudaria isso (vence quem falha primeiro no tempo).
    final perfilFuture = apiClient.buscarPerfil(id);
    final publicacoesFuture = apiClient.buscarPublicacoes(id);

    // Handler já agora: se as publicações falharem enquanto esperamos o perfil
    // (ou se o perfil falhar e ninguém mais esperar por elas), o erro não vira
    // erro assíncrono não tratado. O await abaixo continua recebendo o erro.
    unawaited(publicacoesFuture.then<void>((_) {}, onError: (Object _) {}));

    final completo = await perfilFuture;
    final paginada = await publicacoesFuture;

    return PerfilCompleto(
      usuario: completo.usuario,
      publicacoes: paginada.itens,
      isFollowing: completo.isFollowing,
      seguidoPeloOutro: completo.seguidoPeloOutro,
      totalPublicacoes: paginada.total,
    );
  }

  @override
  Future<void> seguir(String id) => apiClient.seguir(id);

  @override
  Future<void> deixarDeSeguir(String id) => apiClient.deixarDeSeguir(id);

  @override
  Future<String> atualizarFoto(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) => apiClient.atualizarFoto(bytes, filename: filename, mimeType: mimeType);

  @override
  Future<String> atualizarBanner(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) =>
      apiClient.atualizarBanner(bytes, filename: filename, mimeType: mimeType);

  @override
  Future<Usuario> editarPerfil(Map<String, dynamic> camposAlterados) =>
      apiClient.editarPerfil(camposAlterados);

  @override
  Future<bool> verificarUsername(String username) =>
      apiClient.verificarUsername(username);

  @override
  Future<ListaPaginada<UsuarioResumido>> buscarSeguidores(
    String id, {
    int pagina = 1,
    int porPagina = 20,
  }) => apiClient.buscarSeguidores(id, pagina: pagina, porPagina: porPagina);

  @override
  Future<ListaPaginada<UsuarioResumido>> buscarSeguindo(
    String id, {
    int pagina = 1,
    int porPagina = 20,
  }) => apiClient.buscarSeguindo(id, pagina: pagina, porPagina: porPagina);

  Future<ListaPaginada<Publicacao>> buscarPublicacoesPaginadas(
    String id, {
    int pagina = 1,
    int porPagina = 12,
  }) => apiClient.buscarPublicacoes(id, pagina: pagina, porPagina: porPagina);
}
