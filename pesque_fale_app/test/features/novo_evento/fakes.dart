import 'dart:async';
import 'dart:typed_data';

import 'package:pesque_fale_app/features/feed/data/eventos_repository.dart';
import 'package:pesque_fale_app/features/feed/data/upload_publicacao_imagem_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/dados_evento.dart';
import 'package:pesque_fale_app/features/feed/domain/evento.dart';

Evento eventoDe(String id, DadosEvento dados) => Evento(
  id: id,
  titulo: dados.titulo,
  descricao: dados.descricao,
  pontoId: dados.pontoId,
  organizadorId: 'mock-id',
  organizadorNome: 'Ana',
  dataInicio: dados.dataInicio,
  dataFim: dados.dataFim,
  imagemUrl: dados.imagemUrl,
  localTexto: dados.localTexto,
  criadoEm: DateTime(2026, 11, 1),
);

class FakeEventosRepository implements EventosRepository {
  final List<DadosEvento> criados = [];
  final List<(String, DadosEvento)> editados = [];
  Object? erro;
  Completer<void>? segurar;

  Future<void> _talvezFalhar() async {
    final segurar = this.segurar;
    if (segurar != null) await segurar.future;
    final erro = this.erro;
    if (erro != null) throw erro;
  }

  @override
  Future<Evento> criar(DadosEvento dados) async {
    criados.add(dados);
    await _talvezFalhar();
    return eventoDe('ev-novo', dados);
  }

  @override
  Future<Evento> editar(String id, DadosEvento dados) async {
    editados.add((id, dados));
    await _talvezFalhar();
    return eventoDe(id, dados);
  }

  @override
  Future<List<Evento>> listar({bool futuros = true, int limite = 10}) async =>
      const [];

  @override
  Future<Evento> buscarPorId(String id) => throw UnimplementedError();

  @override
  Future<void> excluir(String id) => throw UnimplementedError();
}

class FakeUploadRepository implements UploadPublicacaoImagemRepository {
  final List<String> enviados = [];
  Object? erro;

  @override
  Future<String> upload(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async {
    enviados.add(filename);
    final erro = this.erro;
    if (erro != null) throw erro;
    return 'https://res.cloudinary.com/x/$filename';
  }
}
