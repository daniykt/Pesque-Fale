import 'dart:io';

import '../domain/perfil_completo.dart';

abstract class PerfilRepository {
  /// Busca o perfil completo (usuario + publicacoes + estado de seguimento)
  /// de [id], calculado do ponto de vista de [meuId] (usuário logado).
  Future<PerfilCompleto> buscarPerfil(String id, {required String meuId});

  Future<void> seguir(String id);

  Future<void> deixarDeSeguir(String id);

  /// Retorna a nova URL da foto de perfil.
  Future<String> atualizarFoto(File arquivo);

  /// Retorna a nova URL do banner.
  Future<String> atualizarBanner(File arquivo);
}
