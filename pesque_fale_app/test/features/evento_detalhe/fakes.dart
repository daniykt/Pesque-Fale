import 'dart:async';

import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/feed/data/eventos_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/dados_evento.dart';
import 'package:pesque_fale_app/features/feed/domain/evento.dart';

Evento eventoDeTeste({
  String id = 'ev-1',
  String titulo = 'Torneio do Lago Azul',
  String organizadorId = 'organizador',
  DateTime? inicio,
  DateTime? fim,
  String? descricao = 'Premiação para os três maiores peixes.',
  String? localTexto = 'Lago Azul, Matão-SP',
  String? pontoId,
}) => Evento(
  id: id,
  titulo: titulo,
  descricao: descricao,
  pontoId: pontoId,
  organizadorId: organizadorId,
  organizadorNome: 'Ana Souza',
  organizadorUsername: 'ana_pesca',
  dataInicio: inicio ?? DateTime(2026, 11, 20, 7),
  dataFim: fim,
  localTexto: localTexto,
  criadoEm: DateTime(2026, 11, 1),
);

class FakeEventosDetalheRepository implements EventosRepository {
  FakeEventosDetalheRepository({this.atual});

  Evento? atual;
  Object? erroBuscar;
  Object? erroExcluir;
  Completer<void>? segurarExcluir;
  int buscas = 0;
  final List<String> excluidos = [];

  @override
  Future<Evento> buscarPorId(String id) async {
    buscas++;
    final erro = erroBuscar;
    if (erro != null) throw erro;
    return atual!;
  }

  @override
  Future<void> excluir(String id) async {
    excluidos.add(id);
    final segurar = segurarExcluir;
    if (segurar != null) await segurar.future;
    final erro = erroExcluir;
    if (erro != null) throw erro;
  }

  @override
  Future<List<Evento>> listar({bool futuros = true, int limite = 10}) async =>
      const [];

  @override
  Future<Evento> criar(DadosEvento dados) => throw UnimplementedError();

  @override
  Future<Evento> editar(String id, DadosEvento dados) =>
      throw UnimplementedError();
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.usuarioId);

  final String usuarioId;

  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async => AuthResult(
    accessToken: 'token',
    usuario: Usuario(
      id: usuarioId,
      nome: 'Teste',
      email: 'teste@exemplo.com',
      onboardingConcluido: true,
    ),
  );

  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) => throw UnimplementedError();

  @override
  Future<void> logout() async {}
}
