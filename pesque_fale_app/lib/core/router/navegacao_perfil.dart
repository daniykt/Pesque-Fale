import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import 'main_shell.dart';

/// Abre o perfil de um usuário. Se for o próprio usuário logado, em vez de
/// empilhar a `PerfilDeOutroPage` volta até '/home' e seleciona a aba Perfil
/// do [MainShell], onde ficam os botões de editar e configurar.
void abrirPerfil(
  BuildContext context,
  String usuarioId, {
  ValueChanged<int>? onSelecionarAba, // injetável para testes
}) {
  final meuId = context.read<AuthProvider>().usuario?.id;

  if (meuId != null && usuarioId == meuId) {
    final selecionar =
        onSelecionarAba ??
        (i) => MainShell.shellKey.currentState?.selecionarAba(i);
    // Dentro da aba Pesquisa a rota atual já é '/home' e nada é desempilhado;
    // o popUntil está aqui para a função servir a qualquer ponto de entrada.
    // `|| route.isFirst` impede esvaziar a pilha se '/home' não estiver nela.
    Navigator.of(context).popUntil(
      (route) => route.settings.name == '/home' || route.isFirst,
    );
    selecionar(MainShell.perfilIndex);
    return;
  }

  Navigator.of(context).pushNamed('/perfil', arguments: usuarioId);
}
