enum OnboardingEtapa {
  boasVindas,
  fotoPerfil,
  nomeLocalizacao,
  username,
  bio,
  fotoCapa,
  sucesso;

  int get numeroExibicao => index + 1;

  bool get permitePular {
    switch (this) {
      case OnboardingEtapa.fotoPerfil:
      case OnboardingEtapa.nomeLocalizacao:
      case OnboardingEtapa.bio:
      case OnboardingEtapa.fotoCapa:
        return true;
      case OnboardingEtapa.boasVindas:
      case OnboardingEtapa.username:
      case OnboardingEtapa.sucesso:
        return false;
    }
  }
}
