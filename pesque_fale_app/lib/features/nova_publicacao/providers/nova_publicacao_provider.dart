import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../auth/providers/auth_provider.dart';
import '../../feed/data/publicacoes_repository.dart';
import '../../feed/data/upload_publicacao_imagem_exceptions.dart';
import '../../feed/data/upload_publicacao_imagem_repository.dart';
import '../../feed/domain/publicacao.dart';
import '../../feed/providers/feed_provider.dart';
import '../../pesquisa/domain/ponto.dart';

enum StatusPublicacao { editando, enviando, sucesso, erro }

class NovaPublicacaoProvider extends ChangeNotifier {
  NovaPublicacaoProvider({
    required this.publicacoesRepository,
    required this.uploadRepository,
    required this.feedProvider,
    required this.authProvider,
  });

  final PublicacoesRepository publicacoesRepository;
  final UploadPublicacaoImagemRepository uploadRepository;
  final FeedProvider feedProvider;
  final AuthProvider authProvider;

  File? foto;
  Ponto? pontoSelecionado;
  String descricao = '';
  double? avaliacaoNota;
  final Set<String> tagsSelecionadas = {};
  StatusPublicacao status = StatusPublicacao.editando;
  String? mensagemErro;

  static const int limiteMaximoTags = 5;
  static const int limiteMaximoDescricao = 300;

  bool get temFotoObrigatoria => foto != null;
  bool get temLocalObrigatorio => pontoSelecionado != null;
  bool get podePublicar =>
      temFotoObrigatoria &&
      temLocalObrigatorio &&
      status != StatusPublicacao.enviando;
  bool get formularioSujo =>
      foto != null ||
      pontoSelecionado != null ||
      descricao.isNotEmpty ||
      avaliacaoNota != null ||
      tagsSelecionadas.isNotEmpty;

  void setFoto(File? novaFoto) {
    foto = novaFoto;
    notifyListeners();
  }

  void setPonto(Ponto? novoPonto) {
    pontoSelecionado = novoPonto;
    notifyListeners();
  }

  void setDescricao(String novaDescricao) {
    descricao = novaDescricao.substring(
      0,
      novaDescricao.length.clamp(0, limiteMaximoDescricao),
    );
    notifyListeners();
  }

  void setAvaliacao(double? nota) {
    avaliacaoNota = nota;
    notifyListeners();
  }

  void limparAvaliacao() {
    avaliacaoNota = null;
    notifyListeners();
  }

  /// Retorna true se adicionou, false se atingiu o limite ou tag já existe
  bool adicionarTag(String tag) {
    final normalizada = tag.trim();
    if (normalizada.isEmpty) return false;
    if (tagsSelecionadas.length >= limiteMaximoTags) return false;
    if (tagsSelecionadas.contains(normalizada)) return false;
    tagsSelecionadas.add(normalizada);
    notifyListeners();
    return true;
  }

  void removerTag(String tag) {
    if (tagsSelecionadas.remove(tag)) notifyListeners();
  }

  /// Envia a publicação. Retorna a Publicacao criada em caso de sucesso.
  /// Fluxo: upload da imagem → POST /publicacoes → adiciona no FeedProvider.
  Future<Publicacao?> publicar() async {
    if (!podePublicar) return null;
    status = StatusPublicacao.enviando;
    mensagemErro = null;
    notifyListeners();

    try {
      final imagemUrl = await uploadRepository.upload(foto!);

      final publicacao = await publicacoesRepository.criar(
        descricao: descricao.trim().isEmpty ? null : descricao.trim(),
        imagemUrl: imagemUrl,
        localTexto: pontoSelecionado!.nome,
        avaliacaoNota: avaliacaoNota,
        pontoId: pontoSelecionado!.id,
        tags: tagsSelecionadas.toList(),
      );

      feedProvider.adicionarPublicacao(publicacao);

      status = StatusPublicacao.sucesso;
      notifyListeners();
      return publicacao;
    } on UploadArquivoMuitoGrandeException {
      mensagemErro = 'A imagem é maior que 5MB. Escolha uma menor.';
      status = StatusPublicacao.erro;
      notifyListeners();
      return null;
    } on UploadFormatoInvalidoException {
      mensagemErro = 'Formato inválido. Use JPG, PNG ou WEBP.';
      status = StatusPublicacao.erro;
      notifyListeners();
      return null;
    } catch (_) {
      mensagemErro = 'Não foi possível publicar. Tente novamente.';
      status = StatusPublicacao.erro;
      notifyListeners();
      return null;
    }
  }
}
