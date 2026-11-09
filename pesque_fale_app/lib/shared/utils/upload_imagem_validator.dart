import 'package:image_picker/image_picker.dart';

/// Validações compartilhadas para upload de imagem no app.
///
/// Centraliza formatos aceitos, tamanho máximo e extração de extensão,
/// evitando duplicação entre features (perfil, onboarding, publicação).
/// Consome XFile do image_picker — o handle cross-platform que já é o
/// tipo de trânsito das features que fazem upload.
class UploadImagemValidator {
  const UploadImagemValidator._();

  /// Formatos aceitos pelo backend (bate com validação do api_client
  /// e com o preset do Cloudinary).
  static const formatosAceitos = {'jpg', 'jpeg', 'png', 'webp'};

  /// Tamanho máximo aceito pelo backend (5MB).
  /// Bate com o retorno 413 do api_client em ARQUIVO_MUITO_GRANDE.
  static const tamanhoMaximoBytes = 5 * 1024 * 1024;

  /// Extrai a extensão em minúsculo a partir do `.name` do XFile.
  ///
  /// Usa `.name` (não `.path`) porque no Flutter Web o `.path` pode ser
  /// um blob URL sem extensão (ex: `blob:http://.../abc-123`), enquanto
  /// `.name` sempre traz o nome real que o navegador expôs.
  static String extrairExtensao(XFile arquivo) =>
      arquivo.name.split('.').last.toLowerCase();

  /// True se a extensão está entre os [formatosAceitos].
  static bool formatoValido(XFile arquivo) =>
      formatosAceitos.contains(extrairExtensao(arquivo));

  /// True se o tamanho está dentro do [tamanhoMaximoBytes].
  /// Assíncrono porque XFile.length() lê metadata do arquivo/blob.
  static Future<bool> tamanhoValido(XFile arquivo) async =>
      (await arquivo.length()) <= tamanhoMaximoBytes;
}
