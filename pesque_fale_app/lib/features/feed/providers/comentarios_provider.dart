import 'package:flutter/foundation.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/comentarios_repository.dart';
import '../domain/comentario.dart';

enum StatusComentarios { carregando, sucesso, vazio, erro, carregandoMais }

class ComentariosProvider extends ChangeNotifier {
  ComentariosProvider({
    required this.repository,
    required this.publicacaoId,
    required this.authProvider,
    required this.onCountChange,
  });

  final ComentariosRepository repository;
  final String publicacaoId;
  final AuthProvider authProvider;

  /// Notifica o [FeedProvider] do delta no contador de comentários da
  /// publicação (+1 ao criar, -1 ao deletar).
  final void Function(int delta) onCountChange;

  StatusComentarios _status = StatusComentarios.carregando;
  String? _mensagemErro;
  final List<Comentario> _comentarios = [];

  int _pagina = 1;
  bool _temMais = true;

  StatusComentarios get status => _status;
  String? get mensagemErro => _mensagemErro;
  List<Comentario> get comentarios => List.unmodifiable(_comentarios);
  bool get temMais => _temMais;
  bool get carregandoMais => _status == StatusComentarios.carregandoMais;

  Future<void> carregarInicial() async {
    _status = StatusComentarios.carregando;
    notifyListeners();
    try {
      final result = await repository.listar(publicacaoId, pagina: 1);
      _comentarios
        ..clear()
        ..addAll(result.items);
      _pagina = 1;
      _temMais = result.temMais;
      _status = _comentarios.isEmpty
          ? StatusComentarios.vazio
          : StatusComentarios.sucesso;
    } catch (e) {
      _status = StatusComentarios.erro;
      _mensagemErro = e.toString();
    }
    notifyListeners();
  }

  Future<void> carregarMais() async {
    if (_status == StatusComentarios.carregandoMais ||
        _status == StatusComentarios.carregando ||
        !_temMais) {
      return;
    }

    _status = StatusComentarios.carregandoMais;
    notifyListeners();
    try {
      final proximaPagina = _pagina + 1;
      final result = await repository.listar(
        publicacaoId,
        pagina: proximaPagina,
      );
      _comentarios.addAll(result.items);
      _pagina = proximaPagina;
      _temMais = result.temMais;
      _status = StatusComentarios.sucesso;
    } catch (e) {
      _status = StatusComentarios.erro;
      _mensagemErro = e.toString();
    }
    notifyListeners();
  }

  Future<void> enviar(String texto) async {
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final usuario = authProvider.usuario!;
    final otimista = Comentario(
      id: tempId,
      publicacaoId: publicacaoId,
      autorId: usuario.id,
      autorNome: usuario.nome,
      autorUsername: usuario.username,
      autorFoto: usuario.fotoPerfil,
      texto: texto,
      criadoEm: DateTime.now(),
      enviando: true,
    );

    _comentarios.insert(0, otimista);
    _status = StatusComentarios.sucesso;
    notifyListeners();

    try {
      final criado = await repository.criar(publicacaoId, texto);
      final idx = _comentarios.indexWhere((c) => c.id == tempId);
      if (idx != -1) _comentarios[idx] = criado;
      onCountChange(1);
      notifyListeners();
    } catch (e) {
      _comentarios.removeWhere((c) => c.id == tempId);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletar(String comentarioId) async {
    final idx = _comentarios.indexWhere((c) => c.id == comentarioId);
    if (idx == -1) return;
    final removido = _comentarios[idx];
    _comentarios.removeAt(idx);
    notifyListeners();

    try {
      await repository.deletar(comentarioId);
      onCountChange(-1);
    } catch (e) {
      _comentarios.insert(idx, removido);
      notifyListeners();
      rethrow;
    }
  }
}
