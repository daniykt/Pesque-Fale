enum AutorMensagem { usuario, assistente }

enum TipoAcaoAssistente { abrirLocal, abrirTela }

class AcaoAssistente {
  const AcaoAssistente({
    required this.tipo,
    required this.rotulo,
    this.pontoId,
    this.tela,
  });

  final TipoAcaoAssistente tipo;
  final String rotulo;
  final String? pontoId;
  final String? tela;

  static AcaoAssistente? fromJson(Map<String, dynamic> json) {
    final rotulo = json['rotulo'];
    if (rotulo is! String || rotulo.isEmpty) return null;

    switch (json['tipo']) {
      case 'abrir_local':
        final pontoId = json['pontoId'];
        if (pontoId is! String || pontoId.isEmpty) return null;
        return AcaoAssistente(
          tipo: TipoAcaoAssistente.abrirLocal,
          rotulo: rotulo,
          pontoId: pontoId,
        );
      case 'abrir_tela':
        final tela = json['tela'];
        if (tela is! String || tela.isEmpty) return null;
        return AcaoAssistente(
          tipo: TipoAcaoAssistente.abrirTela,
          rotulo: rotulo,
          tela: tela,
        );
      default:
        return null;
    }
  }
}

class RespostaAssistente {
  const RespostaAssistente({required this.resposta, this.acoes = const []});

  final String resposta;
  final List<AcaoAssistente> acoes;

  factory RespostaAssistente.fromJson(Map<String, dynamic> json) {
    final acoes = (json['acoes'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AcaoAssistente.fromJson)
        .whereType<AcaoAssistente>()
        .toList();
    return RespostaAssistente(
      resposta: (json['resposta'] as String? ?? '').trim(),
      acoes: acoes,
    );
  }
}

class MensagemAssistente {
  const MensagemAssistente({
    required this.autor,
    required this.texto,
    this.acoes = const [],
  });

  const MensagemAssistente.usuario(this.texto)
    : autor = AutorMensagem.usuario,
      acoes = const [];

  final AutorMensagem autor;
  final String texto;
  final List<AcaoAssistente> acoes;

  bool get doUsuario => autor == AutorMensagem.usuario;

  Map<String, String> toHistorico() => {
    'papel': doUsuario ? 'usuario' : 'assistente',
    'texto': texto,
  };
}