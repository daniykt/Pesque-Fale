import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/pesquisa/data/usuarios_busca_repository_mock.dart';

void main() {
  late UsuariosBuscaRepositoryMock repository;

  setUp(() {
    repository = UsuariosBuscaRepositoryMock();
  });

  test('busca case-insensitive por nome', () async {
    final resultado = await repository.buscar('ana');
    expect(resultado, isNotEmpty);
    expect(resultado.first.username, 'ana_pesca');
  });

  test('busca case-insensitive por username', () async {
    final resultado = await repository.buscar('BRUNO_SF');
    expect(resultado, isNotEmpty);
    expect(resultado.first.nome, 'Bruno Sem Foto');
  });

  test('retorna vazio quando texto vazio', () async {
    final resultado = await repository.buscar('');
    expect(resultado, isEmpty);
  });

  test('retorna vazio quando nenhum usuario bate com o texto', () async {
    final resultado = await repository.buscar('zzz-nao-existe');
    expect(resultado, isEmpty);
  });
}
