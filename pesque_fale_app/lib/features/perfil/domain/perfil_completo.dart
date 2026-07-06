import '../../auth/domain/usuario.dart';
import 'publicacao.dart';

class PerfilCompleto {
  const PerfilCompleto({
    required this.usuario,
    this.publicacoes = const [],
    this.isFollowing = false,
    this.seguidoPeloOutro = false,
  });

  final Usuario usuario;
  final List<Publicacao> publicacoes;
  final bool isFollowing;
  final bool seguidoPeloOutro;

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
    );
  }
}
