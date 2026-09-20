import 'dart:typed_data';

import '../../auth/domain/usuario.dart';
import '../domain/perfil_completo.dart';

abstract class PerfilRepository {
  /// Busca o perfil completo (usuario + publicacoes + estado de seguimento)
  /// de [id], calculado do ponto de vista de [meuId] (usuário logado).
  Future<PerfilCompleto> buscarPerfil(String id, {required String meuId});

  Future<void> seguir(String id);

  Future<void> deixarDeSeguir(String id);

  /// Retorna a nova URL. [filename] preserva extensão original pro
  /// Content-Type no multipart.
  Future<String> atualizarFoto(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  });

  /// Retorna a nova URL. [filename] preserva extensão original pro
  /// Content-Type no multipart.
  Future<String> atualizarBanner(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  });

  /// Envia apenas os [camposAlterados] (PATCH parcial) e retorna o Usuario
  /// atualizado.
  Future<Usuario> editarPerfil(Map<String, dynamic> camposAlterados);

  /// Verifica se [username] está disponível para uso.
  Future<bool> verificarUsername(String username);
}
