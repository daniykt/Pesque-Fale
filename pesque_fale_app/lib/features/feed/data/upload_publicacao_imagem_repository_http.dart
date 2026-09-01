import 'dart:io';

import 'upload_publicacao_imagem_api_client.dart';
import 'upload_publicacao_imagem_repository.dart';

class UploadPublicacaoImagemRepositoryHttp
    implements UploadPublicacaoImagemRepository {
  UploadPublicacaoImagemRepositoryHttp({required this.apiClient});

  final UploadPublicacaoImagemApiClient apiClient;

  @override
  Future<String> upload(File arquivo) async {
    final json = await apiClient.upload(arquivo);
    final data = json['data'] as Map<String, dynamic>?;
    final url = data?['imagemUrl'] as String?;
    if (url == null) throw Exception('URL não retornada pelo servidor');
    return url;
  }
}
