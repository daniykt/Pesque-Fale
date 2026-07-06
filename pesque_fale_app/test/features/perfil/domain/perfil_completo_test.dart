import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/perfil/domain/perfil_completo.dart';

void main() {
  group('PerfilCompleto.fromJson', () {
    test('agrega usuario e publicacoes', () {
      final perfil = PerfilCompleto.fromJson({
        'usuario': {
          'id': '1',
          'nome': 'Pescador',
          'email': 'pescador@teste.com',
          'onboardingConcluido': true,
          'seguidores': 5,
          'seguindo': 1,
        },
        'publicacoes': [
          {'id': 'p1', 'autorId': '1', 'imagemUrl': 'https://x/1.png'},
          {'id': 'p2', 'autorId': '1', 'imagemUrl': 'https://x/2.png'},
        ],
        'isFollowing': true,
        'seguidoPeloOutro': false,
      });

      expect(perfil.usuario.id, '1');
      expect(perfil.usuario.seguidores, 5);
      expect(perfil.publicacoes, hasLength(2));
      expect(perfil.isFollowing, isTrue);
      expect(perfil.seguidoPeloOutro, isFalse);
    });

    test('usa defaults quando publicacoes e flags faltam', () {
      final perfil = PerfilCompleto.fromJson({
        'usuario': {
          'id': '2',
          'nome': 'Outro',
          'email': 'outro@teste.com',
          'onboardingConcluido': false,
        },
      });

      expect(perfil.publicacoes, isEmpty);
      expect(perfil.isFollowing, isFalse);
      expect(perfil.seguidoPeloOutro, isFalse);
    });
  });
}
