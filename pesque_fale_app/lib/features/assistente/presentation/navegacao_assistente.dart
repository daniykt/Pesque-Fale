import 'package:flutter/material.dart';

import '../../../core/router/main_shell.dart';
import '../domain/mensagem_assistente.dart';

const rotasDasTelasDoAssistente = {
  'nova_publicacao': '/publicacao/nova',
  'editar_perfil': '/perfil/editar',
  'configuracoes': '/configuracoes',
  'chat': '/chat',
  'sobre': '/sobre',
};

void abrirAcaoDoAssistente(
  BuildContext context,
  AcaoAssistente acao, {
  ValueChanged<int>? onSelecionarAba,
}) {
  final navigator = Navigator.of(context);

  if (acao.tipo == TipoAcaoAssistente.abrirLocal) {
    navigator.pushNamed('/pontos', arguments: acao.pontoId);
    return;
  }

  if (acao.tela == 'pesquisa_locais') {
    final selecionar =
        onSelecionarAba ??
        (i) => MainShell.shellKey.currentState?.selecionarAba(i);
    navigator.popUntil(
      (route) => route.settings.name == '/home' || route.isFirst,
    );
    selecionar(MainShell.pesquisaIndex);
    return;
  }

  final rota = rotasDasTelasDoAssistente[acao.tela];
  if (rota != null) navigator.pushNamed(rota);
}