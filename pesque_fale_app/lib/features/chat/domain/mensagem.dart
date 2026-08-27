enum StatusMensagem { enviado, visto }

class Mensagem {
  const Mensagem({
    required this.id,
    required this.chatId,
    required this.userId,
    required this.nome,
    required this.texto,
    required this.status,
    required this.criadoEm,
  });

  final String id;
  final String chatId;
  final String userId;
  final String nome;
  final String texto;
  final StatusMensagem status;
  final DateTime criadoEm;

  Mensagem copyWith({StatusMensagem? status}) {
    return Mensagem(
      id: id,
      chatId: chatId,
      userId: userId,
      nome: nome,
      texto: texto,
      status: status ?? this.status,
      criadoEm: criadoEm,
    );
  }

  factory Mensagem.fromJson(Map<String, dynamic> json) {
    return Mensagem(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      userId: json['userId'] as String,
      nome: json['nome'] as String,
      texto: json['texto'] as String,
      status: (json['status'] as String) == 'visto'
          ? StatusMensagem.visto
          : StatusMensagem.enviado,
      criadoEm: DateTime.parse(json['criadoEm'] as String).toLocal(),
    );
  }
}
