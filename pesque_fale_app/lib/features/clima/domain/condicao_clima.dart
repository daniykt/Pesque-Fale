enum CondicaoClima {
  ceuLimpo('Céu limpo'),
  poucasNuvens('Poucas nuvens'),
  parcialmenteNublado('Parcialmente nublado'),
  nublado('Nublado'),
  neblina('Neblina'),
  garoa('Garoa'),
  chuva('Chuva'),
  chuvaForte('Chuva forte'),
  pancadasDeChuva('Pancadas de chuva'),
  neve('Neve'),
  trovoada('Trovoada'),
  trovoadaComGranizo('Trovoada com granizo'),
  desconhecida('Condição não informada');

  const CondicaoClima(this.descricao);

  final String descricao;

  static CondicaoClima doCodigo(int codigo) {
    switch (codigo) {
      case 0:
        return ceuLimpo;
      case 1:
        return poucasNuvens;
      case 2:
        return parcialmenteNublado;
      case 3:
        return nublado;
      case 45:
      case 48:
        return neblina;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return garoa;
      case 61:
      case 63:
      case 66:
        return chuva;
      case 65:
      case 67:
        return chuvaForte;
      case 80:
      case 81:
      case 82:
        return pancadasDeChuva;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return neve;
      case 95:
        return trovoada;
      case 96:
      case 99:
        return trovoadaComGranizo;
      default:
        return desconhecida;
    }
  }
}
