import '../../auth/domain/usuario.dart';
import '../../feed/domain/publicacao.dart';

class PerfilCompleto {
  const PerfilCompleto({
    required this.usuario,
    this.publicacoes = const [],
    this.isFollowing = false,
    this.seguidoPeloOutro = false,
    this.totalPublicacoes,
  });

  final Usuario usuario;
  final List<Publicacao> publicacoes;
  final bool isFollowing;
  final bool seguidoPeloOutro;

  /// Total de publicações do usuário (`meta.total` da API). [publicacoes] é
  /// só a primeira página. null quando a origem não informa o total.
  final int? totalPublicacoes;

  factory PerfilCompleto.fromJson(Map<String, dynamic> json) {
    return PerfilCompleto(
      usuario: Usuario.fromJson(
        (json['usuario'] as Map<String, dynamic>?) ?? json,
      ),
      publicacoes:
          (json['publicacoes'] as List<dynamic>?)
              ?.map((e) => Publicacao.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isFollowing: json['isFollowing'] as bool? ?? false,
      seguidoPeloOutro: json['seguidoPeloOutro'] as bool? ?? false,
      totalPublicacoes: json['totalPublicacoes'] as int?,
    );
  }
}
