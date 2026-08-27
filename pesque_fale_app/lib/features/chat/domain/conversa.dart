class Conversa {
  const Conversa({
    required this.id,
    required this.outroId,
    required this.outroNome,
    required this.outroUsername,
    this.outroFoto,
    this.ultimaMensagem,
    this.ultimaMensagemEm,
    required this.naoLidas,
    required this.criadoEm,
  });

  final String id;
  final String outroId;
  final String outroNome;
  final String outroUsername;
  final String? outroFoto;
  final String? ultimaMensagem;
  final DateTime? ultimaMensagemEm;
  final int naoLidas;
  final DateTime criadoEm;

  bool get temMensagem =>
      ultimaMensagem != null && ultimaMensagem!.trim().isNotEmpty;

  factory Conversa.fromJson(Map<String, dynamic> json) {
    return Conversa(
      id: json['id'] as String,
      outroId: json['outroId'] as String,
      outroNome: json['outroNome'] as String,
      outroUsername: json['outroUsername'] as String,
      outroFoto: json['outroFoto'] as String?,
      ultimaMensagem: json['ultimaMensagem'] as String?,
      ultimaMensagemEm: json['ultimaMensagemEm'] != null
          ? DateTime.parse(json['ultimaMensagemEm'] as String).toLocal()
          : null,
      naoLidas: json['naoLidas'] as int? ?? 0,
      criadoEm: DateTime.parse(json['criadoEm'] as String).toLocal(),
    );
  }
}
