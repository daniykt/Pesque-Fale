import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../app_snackbar.dart';
import 'modo_crop.dart';

/// Tela full-screen de enquadramento: o usuário arrasta e dá zoom na imagem
/// dentro de uma área fixa (circular no avatar, 16:9 no banner).
///
/// Devolve via `Navigator.pop` os bytes JPEG já no tamanho final do [modo],
/// ou `null` se o usuário cancelar.
class CropImagemPage extends StatefulWidget {
  const CropImagemPage({
    super.key,
    required this.bytesOriginais,
    required this.modo,
  });

  final Uint8List bytesOriginais;
  final ModoCrop modo;

  @override
  State<CropImagemPage> createState() => _CropImagemPageState();
}

class _CropImagemPageState extends State<CropImagemPage> {
  final _controller = CropController();

  /// Só libera o "Confirmar" depois que o Crop terminou de decodificar a
  /// imagem — antes disso `crop()` não tem o que recortar.
  bool _imagemPronta = false;
  bool _processando = false;

  void _confirmar() {
    setState(() => _processando = true);
    _controller.crop();
  }

  Future<void> _aoRecortar(CropResult resultado) async {
    Uint8List? bytes;
    if (resultado is CropSuccess) {
      try {
        bytes = await compute(redimensionarRecorte, (
          resultado.croppedImage,
          widget.modo.larguraSaida,
          widget.modo.alturaSaida,
        ));
      } catch (_) {
        bytes = null;
      }
    }
    if (!mounted) return;

    if (bytes == null) {
      setState(() => _processando = false);
      AppSnackbar.showError(
        context,
        'Não foi possível ajustar a imagem. Tente outra.',
      );
      return;
    }
    Navigator.pop(context, bytes);
  }

  @override
  Widget build(BuildContext context) {
    final modo = widget.modo;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancelar',
          onPressed: _processando ? null : () => Navigator.pop(context),
        ),
        title: Text(modo.circular ? 'Ajustar foto' : 'Ajustar banner'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: _imagemPronta && !_processando ? _confirmar : null,
            child: const Text('Confirmar'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Crop(
              image: widget.bytesOriginais,
              controller: _controller,
              onCropped: _aoRecortar,
              onStatusChanged: (status) {
                if (status == CropStatus.ready && !_imagemPronta) {
                  setState(() => _imagemPronta = true);
                }
              },
              withCircleUi: modo.circular,
              aspectRatio: modo.aspectRatio,
              initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                size: 0.9,
                aspectRatio: modo.aspectRatio,
              ),
              // Área fixa + imagem móvel (pan/zoom), padrão de app social.
              interactive: true,
              fixCropRect: true,
              baseColor: Colors.black,
              maskColor: Colors.black.withValues(alpha: 0.6),
              cornerDotBuilder: (_, _) => const SizedBox.shrink(),
              progressIndicator: const CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
          if (_processando)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Redimensiona o recorte pro tamanho fixo do modo e reencoda como JPEG q85.
///
/// Top-level pra rodar via `compute` — decodificar e reencodar em Dart puro
/// trava a UI se for na main isolate.
@visibleForTesting
Uint8List? redimensionarRecorte((Uint8List, int, int) args) {
  final (bytes, largura, altura) = args;
  final recorte = img.decodeImage(bytes);
  if (recorte == null) return null;

  var saida = img.copyResize(
    recorte,
    width: largura,
    height: altura,
    interpolation: img.Interpolation.average,
  );

  // JPEG não tem canal alfa: sem achatar, um PNG transparente vira fundo preto.
  if (saida.hasAlpha) {
    saida = img.compositeImage(
      img.Image(width: largura, height: altura)
        ..clear(img.ColorRgb8(255, 255, 255)),
      saida,
    );
  }

  return img.encodeJpg(saida, quality: 85);
}
