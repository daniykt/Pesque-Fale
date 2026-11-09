import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/onboarding/domain/onboarding_etapa.dart';

void main() {
  test('numeroExibicao retorna 1 para boasVindas e 7 para sucesso', () {
    expect(OnboardingEtapa.boasVindas.numeroExibicao, 1);
    expect(OnboardingEtapa.sucesso.numeroExibicao, 7);
  });

  test(
    'permitePular retorna false para boasVindas, username e sucesso; true para as demais',
    () {
      expect(OnboardingEtapa.boasVindas.permitePular, isFalse);
      expect(OnboardingEtapa.username.permitePular, isFalse);
      expect(OnboardingEtapa.sucesso.permitePular, isFalse);

      expect(OnboardingEtapa.fotoPerfil.permitePular, isTrue);
      expect(OnboardingEtapa.nomeLocalizacao.permitePular, isTrue);
      expect(OnboardingEtapa.bio.permitePular, isTrue);
      expect(OnboardingEtapa.fotoCapa.permitePular, isTrue);
    },
  );
}
