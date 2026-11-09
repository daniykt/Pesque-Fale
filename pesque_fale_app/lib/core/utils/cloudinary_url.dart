/// Helper para gerar URLs de imagem otimizadas a partir de uma URL do
/// Cloudinary, injetando uma transformação logo após o segmento `/upload/`.
///
/// Se a URL não for reconhecida como uma URL do Cloudinary (sem `/upload/`),
/// retorna a URL original sem alterações.
class CloudinaryUrl {
  CloudinaryUrl._();

  static const _uploadMarker = '/upload/';

  static String otimizar(
    String url, {
    required int largura,
    required int altura,
  }) {
    final indice = url.indexOf(_uploadMarker);
    if (indice == -1) return url;

    final inicio = indice + _uploadMarker.length;
    final transformacao = 'c_fill,w_$largura,h_$altura,q_auto,f_auto';
    return '${url.substring(0, inicio)}$transformacao/${url.substring(inicio)}';
  }

  static String coverCard(String url) =>
      otimizar(url, largura: 800, altura: 450);

  static String? avatar(String? url, {int tamanho = 80}) {
    if (url == null || url.isEmpty) return null;
    return otimizar(url, largura: tamanho, altura: tamanho);
  }
}
