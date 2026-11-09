/// Formato do recorte e da imagem final gerada pela `CropImagemPage`.
///
/// O banner é 16:9 porque é a proporção do `CampoBanner` e do
/// `CabecalhoPerfil` — mudar aqui sem mudar lá distorce o perfil.
enum ModoCrop {
  /// Circular, 1:1, saída 512x512.
  avatar,

  /// Retangular, 16:9, saída 1600x900.
  banner;

  bool get circular => this == ModoCrop.avatar;

  double get aspectRatio => this == ModoCrop.avatar ? 1.0 : 16 / 9;

  int get larguraSaida => this == ModoCrop.avatar ? 512 : 1600;

  int get alturaSaida => this == ModoCrop.avatar ? 512 : 900;
}
