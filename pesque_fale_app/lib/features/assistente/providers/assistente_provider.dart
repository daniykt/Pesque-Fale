import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/assistente_exceptions.dart';
import '../data/assistente_repository.dart';
import '../domain/mensagem_assistente.dart';

class AssistenteProvider extends ChangeNotifier {
  AssistenteProvider({
    required this.repository,
    this.avisoDemora = const Duration(seconds: 5),
  });

  final AssistenteRepository repository;
  final Duration avisoDemora;

  static const sugestoes = [
    'Como publico uma pescaria?',
    'Onde fica o Lago Azul?',
    'Como mudo minha foto de perfil?',
    'Como encontro pessoas para seguir?',
  ];

  static const _tamanhoHistorico = 6;

  final List<MensagemAssistente> _mensagens = [];
  bool _enviando = false;
  bool _demorando = false;
  String? _erro;
  String? _perguntaComErro;
  Timer? _timerDemora;
  bool _descartado = false;

  List<MensagemAssistente> get mensagens => List.unmodifiable(_mensagens);
  bool get enviando => _enviando;
  bool get demorando => _demorando;
  String? get erro => _erro;
  bool get conversaVazia => _mensagens.isEmpty;

  Future<void> enviar(String texto) async {
    final pergunta = texto.trim();
    if (pergunta.isEmpty || _enviando) return;

    final historico = _ultimas(_mensagens);
    _mensagens.add(MensagemAssistente.usuario(pergunta));
    await _perguntar(pergunta, historico);
  }

  Future<void> tentarDeNovo() async {
    final pergunta = _perguntaComErro;
    if (pergunta == null || _enviando) return;

    final anteriores = _mensagens.isEmpty
        ? const <MensagemAssistente>[]
        : _mensagens.sublist(0, _mensagens.length - 1);
    await _perguntar(pergunta, _ultimas(anteriores));
  }

  List<MensagemAssistente> _ultimas(List<MensagemAssistente> lista) {
    if (lista.length <= _tamanhoHistorico) return List.of(lista);
    return lista.sublist(lista.length - _tamanhoHistorico);
  }

  Future<void> _perguntar(
    String pergunta,
    List<MensagemAssistente> historico,
  ) async {
    _enviando = true;
    _demorando = false;
    _erro = null;
    _perguntaComErro = null;
    _timerDemora?.cancel();
    _timerDemora = Timer(avisoDemora, () {
      if (_descartado || !_enviando) return;
      _demorando = true;
      notifyListeners();
    });
    _notificar();

    try {
      final resposta = await repository.perguntar(
        mensagem: pergunta,
        historico: historico,
      );
      _mensagens.add(
        MensagemAssistente(
          autor: AutorMensagem.assistente,
          texto: resposta.resposta,
          acoes: resposta.acoes,
        ),
      );
    } on AssistenteException catch (e) {
      _erro = e.message;
      _perguntaComErro = pergunta;
    } catch (_) {
      _erro = const InternalServerException().message;
      _perguntaComErro = pergunta;
    } finally {
      _timerDemora?.cancel();
      _enviando = false;
      _demorando = false;
      _notificar();
    }
  }

  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _timerDemora?.cancel();
    super.dispose();
  }
}