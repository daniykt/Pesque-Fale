import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_exceptions.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository_mock.dart';

void main() {
  late PerfilRepositoryMock repository;

  setUp(() {
    repository = PerfilRepositoryMock();
  });

  group('PerfilRepositoryMock.buscarPerfil', () {
    test('retorna perfil com publicacoes para usuario com posts', () async {
      final perfil = await repository.buscarPerfil('mock-id', meuId: 'mock-id');

      expect(perfil.usuario.id, 'mock-id');
      expect(perfil.publicacoes, hasLength(5));
    });

    test('cobre o combo de estado vazio total', () async {
      final perfil = await repository.buscarPerfil('mock-3', meuId: 'mock-id');

      expect(perfil.usuario.temFoto, isFalse);
      expect(perfil.usuario.temBanner, isFalse);
      expect(perfil.usuario.bio, isNull);
      expect(perfil.usuario.localizacao, isNull);
      expect(perfil.usuario.seguidores, 0);
      expect(perfil.publicacoes, isEmpty);
    });

    test('lanca PerfilNaoEncontradoException para id desconhecido', () {
      expect(
        () => repository.buscarPerfil('id-invalido', meuId: 'mock-id'),
        throwsA(isA<PerfilNaoEncontradoException>()),
      );
    });
  });

  group('PerfilRepositoryMock.seguir/deixarDeSeguir', () {
    test('atualiza o estado de seguimento entre chamadas', () async {
      var perfil = await repository.buscarPerfil('mock-3', meuId: 'mock-id');
      expect(perfil.isFollowing, isFalse);

      await repository.seguir('mock-3');
      perfil = await repository.buscarPerfil('mock-3', meuId: 'mock-id');
      expect(perfil.isFollowing, isTrue);

      await repository.deixarDeSeguir('mock-3');
      perfil = await repository.buscarPerfil('mock-3', meuId: 'mock-id');
      expect(perfil.isFollowing, isFalse);
    });
  });
}
