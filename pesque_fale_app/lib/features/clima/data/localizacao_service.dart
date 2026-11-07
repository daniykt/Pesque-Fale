import 'package:geolocator/geolocator.dart';

enum MotivoSemLocalizacao { servicoDesligado, negada, negadaParaSempre }

sealed class ResultadoLocalizacao {
  const ResultadoLocalizacao();
}

class LocalizacaoObtida extends ResultadoLocalizacao {
  const LocalizacaoObtida({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LocalizacaoIndisponivel extends ResultadoLocalizacao {
  const LocalizacaoIndisponivel(this.motivo);

  final MotivoSemLocalizacao motivo;
}

abstract class LocalizacaoService {
  Future<ResultadoLocalizacao> obter({required bool pedirPermissao});

  Future<void> abrirConfiguracoes(MotivoSemLocalizacao motivo);
}

class LocalizacaoServiceGeolocator implements LocalizacaoService {
  static const _timeout = Duration(seconds: 15);

  @override
  Future<ResultadoLocalizacao> obter({required bool pedirPermissao}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocalizacaoIndisponivel(
        MotivoSemLocalizacao.servicoDesligado,
      );
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied && pedirPermissao) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.deniedForever) {
      return const LocalizacaoIndisponivel(
        MotivoSemLocalizacao.negadaParaSempre,
      );
    }
    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.unableToDetermine) {
      return const LocalizacaoIndisponivel(MotivoSemLocalizacao.negada);
    }

    final posicao = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
      timeLimit: _timeout,
    );
    return LocalizacaoObtida(
      latitude: posicao.latitude,
      longitude: posicao.longitude,
    );
  }

  @override
  Future<void> abrirConfiguracoes(MotivoSemLocalizacao motivo) async {
    switch (motivo) {
      case MotivoSemLocalizacao.servicoDesligado:
        await Geolocator.openLocationSettings();
      case MotivoSemLocalizacao.negadaParaSempre:
        await Geolocator.openAppSettings();
      case MotivoSemLocalizacao.negada:
        break;
    }
  }
}
