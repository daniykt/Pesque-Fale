enum TipoNotificacao {
  seguindo,
  curtida,
  comentario,
  mensagem,
  sistema;

  static TipoNotificacao fromString(String? s) {
    switch (s) {
      case 'seguindo':
        return TipoNotificacao.seguindo;
      case 'curtida':
        return TipoNotificacao.curtida;
      case 'comentario':
        return TipoNotificacao.comentario;
      case 'mensagem':
        return TipoNotificacao.mensagem;
      default:
        return TipoNotificacao.sistema;
    }
  }
}

class Notificacao {
  const Notificacao({
    required this.id,
    required this.para,
    this.deId,
    this.de,
    this.deUsername,
    this.deFoto,
    required this.tipo,
    this.texto,
    this.postId,
    this.chatId,
    required this.lida,
    this.jaSigoDe,
    required this.criadoEm,
  });

  final String id;
  final String para;
  final String? deId;
  final String? de;
  final String? deUsername;
  final String? deFoto;
  final TipoNotificacao tipo;
  final String? texto;
  final String? postId;
  final String? chatId;
  final bool lida;
  final bool? jaSigoDe;
  final DateTime criadoEm;

  Notificacao copyWith({bool? lida, bool? jaSigoDe}) => Notificacao(
    id: id,
    para: para,
    deId: deId,
    de: de,
    deUsername: deUsername,
    deFoto: deFoto,
    tipo: tipo,
    texto: texto,
    postId: postId,
    chatId: chatId,
    lida: lida ?? this.lida,
    jaSigoDe: jaSigoDe ?? this.jaSigoDe,
    criadoEm: criadoEm,
  );

  factory Notificacao.fromJson(Map<String, dynamic> json) => Notificacao(
    id: json['id'] as String,
    para: json['para'] as String,
    deId: json['deId'] as String?,
    de: json['de'] as String?,
    deUsername: json['deUsername'] as String?,
    deFoto: json['deFoto'] as String?,
    tipo: TipoNotificacao.fromString(json['tipo'] as String?),
    texto: json['texto'] as String?,
    postId: json['postId'] as String?,
    chatId: json['chatId'] as String?,
    lida: json['lida'] as bool? ?? false,
    jaSigoDe: json['jaSigoDe'] as bool?,
    criadoEm: DateTime.parse(json['criadoEm'] as String).toLocal(),
  );
}
