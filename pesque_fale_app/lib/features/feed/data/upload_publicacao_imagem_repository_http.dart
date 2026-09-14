import 'dart:typed_data';

import 'upload_publicacao_imagem_api_client.dart';
import 'upload_publicacao_imagem_repository.dart';

class UploadPublicacaoImagemRepositoryHttp
    implements UploadPublicacaoImagemRepository {
  UploadPublicacaoImagemRepositoryHttp({required this.apiClient});

  final UploadPublicacaoImagemApiClient apiClient;

  @override
  Future<String> upload(Uint8List bytes, {required String filename}) async {
    final json = await apiClient.upload(bytes, filename: filename);
    final data = json['data'] as Map<String, dynamic>?;
    final url = data?['imagemUrl'] as String?;
    if (url == null) throw Exception('URL não retornada pelo servidor');
    return url;
  }
}
