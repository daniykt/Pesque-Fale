import 'package:flutter/foundation.dart';

import '../../feed/data/eventos_exceptions.dart';
import '../../feed/data/eventos_repository.dart';
import '../../feed/data/upload_publicacao_imagem_exceptions.dart';
import '../../feed/data/upload_publicacao_imagem_repository.dart';
import '../../feed/domain/dados_evento.dart';
import '../../feed/domain/evento.dart';
import '../../pesquisa/domain/ponto.dart';

enum StatusNovoEvento { editando, enviando, sucesso, erro }

class PontoDoEvento {
  const PontoDoEvento({required this.id, required this.nome, this.regiao});

  factory PontoDoEvento.dePonto(Ponto ponto) => PontoDoEvento(
    id: ponto.id,
    nome: ponto.nome,
    regiao: '${ponto.cidade}-${ponto.estado}',
  );

  final String id;
  final String nome;
  final String? regiao;
}

class NovoEventoProvider extends ChangeNotifier {
  NovoEventoProvider({
    required this.repository,
    required this.uploadRepository,
    this.evento,
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    final evento = this.evento;
    if (evento == null) return;
    titulo = evento.titulo;
    descricao = evento.descricao ?? '';
    dataInicio = evento.dataInicio;
    dataFim = evento.dataFim;
    imagemUrlAtual = evento.imagemUrl;
    final pontoId = evento.pontoId;
    if (pontoId != null) {
      ponto = PontoDoEvento(id: pontoId, nome: evento.localTexto ?? 'Ponto');
    } else {
      localTexto = evento.localTexto ?? '';
    }
  }

  static const limiteTitulo = 200;
  static const limiteLocal = 150;
  static const limiteDescricao = 1000;

  final EventosRepository repository;
  final UploadPublicacaoImagemRepository uploadRepository;
  final Evento? evento;
  final DateTime Function() _agora;

  String titulo = '';
  String descricao = '';
  String localTexto = '';
  PontoDoEvento? ponto;
  DateTime? dataInicio;
  DateTime? dataFim;
  Uint8List? fotoBytes;
  String? fotoFilename;
  String? fotoMimeType;
  String? imagemUrlAtual;

  StatusNovoEvento status = StatusNovoEvento.editando;
  String? mensagemErro;
  Map<String, String> errosPorCampo = const {};
  bool _alterado = false;

  bool get editando => evento != null;
  bool get enviando => status == StatusNovoEvento.enviando;
  bool get formularioSujo => _alterado && status != StatusNovoEvento.sucesso;

  String? erroDe(String campo) => errosPorCampo[campo];

  void setTitulo(String valor) {
    titulo = valor;
    _mudou('titulo');
  }

  void setDescricao(String valor) {
    descricao = valor.length > limiteDescricao
        ? valor.substring(0, limiteDescricao)
        : valor;
    _mudou('descricao');
  }

  void setLocalTexto(String valor) {
    localTexto = valor;
    _mudou('localTexto');
  }

  void setPonto(PontoDoEvento? novo) {
    ponto = novo;
    _mudou('localTexto', tambem: 'pontoId');
  }

  void setDataInicio(DateTime? valor) {
    dataInicio = valor;
    _mudou('dataInicio', tambem: 'dataFim');
  }

  void setDataFim(DateTime? valor) {
    dataFim = valor;
    _mudou('dataFim');
  }

  void setFoto({Uint8List? bytes, String? filename, String? mimeType}) {
    fotoBytes = bytes;
    fotoFilename = filename;
    fotoMimeType = mimeType;
    _mudou('imagemUrl');
  }

  void removerFoto() {
    fotoBytes = null;
    fotoFilename = null;
    fotoMimeType = null;
    imagemUrlAtual = null;
    _mudou('imagemUrl');
  }

  Map<String, String> validar() {
    final erros = <String, String>{};
    final tituloLimpo = titulo.trim();
    if (tituloLimpo.length < 2 || tituloLimpo.length > limiteTitulo) {
      erros['titulo'] = 'O título precisa ter entre 2 e 200 caracteres.';
    }
    if (ponto == null && localTexto.trim().length > limiteLocal) {
      erros['localTexto'] = 'O local pode ter no máximo 150 caracteres.';
    }
    final inicio = dataInicio;
    if (inicio == null) {
      erros['dataInicio'] = 'Escolha a data e a hora de início.';
    } else if (_inicioPrecisaSerFuturo(inicio) && !inicio.isAfter(_agora())) {
      erros['dataInicio'] = 'O início precisa ser depois de agora.';
    }
    final fim = dataFim;
    if (inicio != null && fim != null && !fim.isAfter(inicio)) {
      erros['dataFim'] = 'O fim precisa ser depois do início.';
    }
    return erros;
  }

  Future<Evento?> enviar() async {
    if (enviando) return null;

    final erros = validar();
    if (erros.isNotEmpty) {
      errosPorCampo = erros;
      mensagemErro = 'Confira os campos destacados.';
      status = StatusNovoEvento.erro;
      notifyListeners();
      return null;
    }

    status = StatusNovoEvento.enviando;
    mensagemErro = null;
    errosPorCampo = const {};
    notifyListeners();

    try {
      var imagemUrl = imagemUrlAtual;
      final bytes = fotoBytes;
      if (bytes != null) {
        imagemUrl = await uploadRepository.upload(
          bytes,
          filename: fotoFilename ?? 'evento.jpg',
          mimeType: fotoMimeType ?? 'image/jpeg',
        );
        imagemUrlAtual = imagemUrl;
        fotoBytes = null;
      }

      final dados = _montarDados(imagemUrl);
      final evento = this.evento;
      final salvo = evento == null
          ? await repository.criar(dados)
          : await repository.editar(evento.id, dados);

      status = StatusNovoEvento.sucesso;
      notifyListeners();
      return salvo;
    } on EventoValidacaoException catch (e) {
      errosPorCampo = e.errosPorCampo;
      mensagemErro = e.errosPorCampo.isEmpty
          ? e.message
          : 'Confira os campos destacados.';
    } on UploadArquivoMuitoGrandeException {
      mensagemErro = 'A imagem é maior que 5MB. Escolha uma menor.';
    } on UploadFormatoInvalidoException {
      mensagemErro = 'Formato inválido. Use JPG, PNG ou WEBP.';
    } on EventosException catch (e) {
      mensagemErro = e.message;
    } catch (_) {
      mensagemErro = 'Não foi possível salvar o evento. Tente novamente.';
    }
    status = StatusNovoEvento.erro;
    notifyListeners();
    return null;
  }

  bool _inicioPrecisaSerFuturo(DateTime inicio) {
    final original = evento?.dataInicio;
    return original == null || !inicio.isAtSameMomentAs(original);
  }

  DadosEvento _montarDados(String? imagemUrl) {
    final ponto = this.ponto;
    final local = localTexto.trim();
    final texto = descricao.trim();
    return DadosEvento(
      titulo: titulo.trim(),
      descricao: texto.isEmpty ? null : texto,
      dataInicio: dataInicio!,
      dataFim: dataFim,
      localTexto: ponto?.nome ?? (local.isEmpty ? null : local),
      pontoId: ponto?.id,
      imagemUrl: imagemUrl,
    );
  }

  void _mudou(String campo, {String? tambem}) {
    _alterado = true;
    if (errosPorCampo.containsKey(campo) ||
        (tambem != null && errosPorCampo.containsKey(tambem))) {
      errosPorCampo = Map.of(errosPorCampo)
        ..remove(campo)
        ..remove(tambem);
    }
    notifyListeners();
  }
}
