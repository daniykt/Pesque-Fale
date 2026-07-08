import 'package:flutter/foundation.dart';

import '../data/avaliacoes_exceptions.dart';
import '../data/avaliacoes_repository.dart';
import '../domain/avaliacao.dart';
import '../domain/criar_editar_avaliacao_input.dart';

enum AvaliarStatus { editando, salvando, sucesso, erro }

class AvaliarProvider extends ChangeNotifier {
  AvaliarProvider({required this.repository});

  final AvaliacoesRepository repository;

  static const _comentarioMaxLength = 500;

  AvaliarStatus _status = AvaliarStatus.editando;
  double _nota = 0;
  String _comentario = '';
  bool _ehEdicao = false;
  String? _mensagemErro;

  AvaliarStatus get status => _status;
  double get nota => _nota;
  String get comentario => _comentario;
  bool get ehEdicao => _ehEdicao;
  String? get mensagemErro => _mensagemErro;
  bool get podeSalvar => _nota > 0;

  void inicializar({Avaliacao? existente}) {
    _ehEdicao = existente != null;
    _nota = existente?.nota ?? 0;
    _comentario = existente?.comentario ?? '';
    _status = AvaliarStatus.editando;
    _mensagemErro = null;
    notifyListeners();
  }

  void alterarNota(double nova) {
    _nota = nova.clamp(1.0, 5.0);
    notifyListeners();
  }

  void alterarComentario(String texto) {
    _comentario = texto.length > _comentarioMaxLength
        ? texto.substring(0, _comentarioMaxLength)
        : texto;
    notifyListeners();
  }

  Future<Avaliacao?> salvar(String pontoId) async {
    if (!podeSalvar) return null;

    _status = AvaliarStatus.salvando;
    _mensagemErro = null;
    notifyListeners();

    final input = CriarEditarAvaliacaoInput(
      nota: _nota,
      comentario: _comentario.trim().isEmpty ? null : _comentario.trim(),
    );

    try {
      final resultado = _ehEdicao
          ? await repository.editar(pontoId, input)
          : await repository.criar(pontoId, input);
      _status = AvaliarStatus.sucesso;
      notifyListeners();
      return resultado;
    } on AvaliacoesException catch (e) {
      _mensagemErro = e.message;
      _status = AvaliarStatus.erro;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deletar(String pontoId) async {
    if (!_ehEdicao) return false;

    _status = AvaliarStatus.salvando;
    _mensagemErro = null;
    notifyListeners();

    try {
      await repository.deletar(pontoId);
      _status = AvaliarStatus.sucesso;
      notifyListeners();
      return true;
    } on AvaliacoesException catch (e) {
      _mensagemErro = e.message;
      _status = AvaliarStatus.erro;
      notifyListeners();
      return false;
    }
  }
}
