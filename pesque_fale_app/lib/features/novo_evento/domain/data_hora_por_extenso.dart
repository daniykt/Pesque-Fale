import '../../clima/domain/data_por_extenso.dart';

String dataHoraPorExtenso(DateTime data) {
  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  return '${dataPorExtenso(data)} de ${data.year}, '
      'às ${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
}
