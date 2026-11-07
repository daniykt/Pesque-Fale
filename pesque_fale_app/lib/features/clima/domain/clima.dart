import 'condicao_clima.dart';

class Clima {
  const Clima({
    required this.temperatura,
    required this.umidade,
    required this.ventoKmh,
    required this.condicao,
  });

  final double temperatura;
  final int umidade;
  final double ventoKmh;
  final CondicaoClima condicao;

  factory Clima.fromOpenMeteo(Map<String, dynamic> json) {
    final atual = json['current'];
    if (atual is! Map) throw const FormatException('current ausente');
    final temperatura = atual['temperature_2m'];
    final umidade = atual['relative_humidity_2m'];
    final vento = atual['wind_speed_10m'];
    final codigo = atual['weather_code'];
    if (temperatura is! num ||
        umidade is! num ||
        vento is! num ||
        codigo is! num) {
      throw const FormatException('campos do clima ausentes');
    }
    return Clima(
      temperatura: temperatura.toDouble(),
      umidade: umidade.round(),
      ventoKmh: vento.toDouble(),
      condicao: CondicaoClima.doCodigo(codigo.toInt()),
    );
  }
}
