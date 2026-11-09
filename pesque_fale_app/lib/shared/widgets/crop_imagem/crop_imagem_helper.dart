import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../features/perfil/data/perfil_exceptions.dart';
import '../../utils/upload_imagem_validator.dart';
import '../app_snackbar.dart';
import 'crop_imagem_page.dart';
import 'modo_crop.dart';
import 'origem_imagem_sheet.dart';

class CropImagemHelper {
  CropImagemHelper._();

  /// Lado máximo pedido ao image_picker. O recorte é decodificado em Dart
  /// puro — uma foto de câmera de 12MP+ demora segundos e pesa centenas de MB
  /// em memória. 2048 ainda sobra pro banner (1600 de largura) com zoom.
  static const _ladoMaximoOrigem = 2048.0;

  /// Abre a [CropImagemPage] e devolve os bytes recortados, ou `null` se o
  /// usuário cancelar.
  static Future<Uint8List?> abrirCrop(
    BuildContext context, {
    required Uint8List bytes,
    required ModoCrop modo,
  }) {
    return Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CropImagemPage(bytesOriginais: bytes, modo: modo),
      ),
    );
  }

  /// Fluxo completo dos campos de foto/banner: origem (câmera ou galeria) →
  /// picker → validação do arquivo original → crop.
  ///
  /// Erros viram snackbar aqui mesmo. Devolve `null` em qualquer cancelamento
  /// ou falha — quem chama só precisa tratar o caso de sucesso.
  static Future<Uint8List?> escolherECortar(
    BuildContext context, {
    required ModoCrop modo,
  }) async {
    final origem = await OrigemImagemSheet.show(context);
    if (origem == null || !context.mounted) return null;

    final arquivo = await _escolherArquivo(context, origem);
    if (arquivo == null || !context.mounted) return null;

    // Valida o arquivo de entrada; a saída do crop é sempre JPEG de tamanho
    // fixo, então não precisa revalidar depois.
    if (!UploadImagemValidator.formatoValido(arquivo)) {
      AppSnackbar.showError(context, const FormatoInvalidoException().message);
      return null;
    }
    final tamanhoOk = await UploadImagemValidator.tamanhoValido(arquivo);
    if (!context.mounted) return null;
    if (!tamanhoOk) {
      AppSnackbar.showError(context, const FotoMuitoGrandeException().message);
      return null;
    }

    final bytes = await arquivo.readAsBytes();
    if (!context.mounted) return null;
    return abrirCrop(context, bytes: bytes, modo: modo);
  }

  static Future<XFile?> _escolherArquivo(
    BuildContext context,
    ImageSource origem,
  ) async {
    if (origem == ImageSource.camera &&
        !await _permissaoCameraLiberada(context)) {
      return null;
    }

    try {
      return await ImagePicker().pickImage(
        source: origem,
        imageQuality: 90,
        maxWidth: _ladoMaximoOrigem,
        maxHeight: _ladoMaximoOrigem,
      );
    } on PlatformException catch (e) {
      if (!context.mounted) return null;
      // No iOS o sistema só mostra o pedido de câmera uma vez: a negação já
      // é permanente e o image_picker devolve este código.
      if (e.code == 'camera_access_denied') {
        _avisarCameraBloqueada(context);
      } else {
        AppSnackbar.showError(context, 'Não foi possível abrir a imagem.');
      }
      return null;
    }
  }

  /// No Android pede a permissão antes do image_picker, porque ele só devolve
  /// "negado" sem dizer se foi permanente. Negada uma vez → silêncio; negada
  /// de vez → snackbar pra abrir as configurações.
  ///
  /// Nas outras plataformas quem pede é o próprio image_picker (no iOS o
  /// permission_handler exigiria a macro PERMISSION_CAMERA no Podfile).
  static Future<bool> _permissaoCameraLiberada(BuildContext context) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;

    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied && context.mounted) {
      _avisarCameraBloqueada(context);
    }
    return status.isGranted;
  }

  static void _avisarCameraBloqueada(BuildContext context) {
    AppSnackbar.showWarning(
      context,
      'Permissão de câmera necessária. Abra as configurações do app.',
      acaoLabel: 'Abrir',
      onAcao: openAppSettings,
    );
  }
}
