import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';

void main() {
  const base = Usuario(
    id: '1',
    nome: 'Pescador',
    email: 'pescador@teste.com',
    onboardingConcluido: true,
    seguidores: 2,
    seguindo: 3,
  );

  group('Usuario.temFoto', () {
    test('false quando fotoPerfil é nulo', () {
      expect(base.temFoto, isFalse);
    });

    test('false quando fotoPerfil é vazio', () {
      expect(base.copyWith(fotoPerfil: '').temFoto, isFalse);
    });

    test('true quando fotoPerfil tem valor', () {
      expect(base.copyWith(fotoPerfil: 'https://x/y.png').temFoto, isTrue);
    });
  });

  group('Usuario.temBanner', () {
    test('false quando banner é nulo', () {
      expect(base.temBanner, isFalse);
    });

    test('true quando banner tem valor', () {
      expect(base.copyWith(banner: 'https://x/banner.png').temBanner, isTrue);
    });
  });

  group('Usuario.copyWith', () {
    test('mantém campos não informados', () {
      final atualizado = base.copyWith(nome: 'Novo Nome');

      expect(atualizado.nome, 'Novo Nome');
      expect(atualizado.id, base.id);
      expect(atualizado.email, base.email);
      expect(atualizado.seguidores, base.seguidores);
      expect(atualizado.seguindo, base.seguindo);
      expect(atualizado.onboardingConcluido, base.onboardingConcluido);
    });

    test('atualiza contadores independentemente', () {
      final atualizado = base.copyWith(seguidores: base.seguidores + 1);

      expect(atualizado.seguidores, 3);
      expect(atualizado.seguindo, base.seguindo);
    });
  });
}
