import 'package:flutter/widgets.dart';

import '../../domain/notificacao.dart';

List<TextSpan> spansDaNotificacao(
  Notificacao n,
  TextStyle base,
  TextStyle bold,
) {
  final nome = n.de ?? 'Alguém';
  switch (n.tipo) {
    case TipoNotificacao.seguindo:
      return [
        TextSpan(text: nome, style: bold),
        TextSpan(text: ' começou a seguir você', style: base),
      ];
    case TipoNotificacao.curtida:
      return [
        TextSpan(text: nome, style: bold),
        TextSpan(text: ' curtiu sua publicação', style: base),
      ];
    case TipoNotificacao.comentario:
      return [
        TextSpan(text: nome, style: bold),
        TextSpan(text: ' comentou: ${_trunc(n.texto, 60)}', style: base),
      ];
    case TipoNotificacao.mensagem:
      return [
        TextSpan(text: nome, style: bold),
        TextSpan(
          text: ' enviou uma mensagem: ${_trunc(n.texto, 60)}',
          style: base,
        ),
      ];
    case TipoNotificacao.sistema:
      return [TextSpan(text: n.texto ?? 'Notificação do sistema', style: base)];
  }
}

String _trunc(String? s, int limite) =>
    s == null ? '' : (s.length > limite ? '${s.substring(0, limite)}...' : s);
