class UsuarioResumo {
  const UsuarioResumo({
    required this.id,
    required this.nome,
    required this.username,
    this.fotoPerfil,
    this.bio = '',
  });

  final String id;
  final String nome;
  final String username;
  final String? fotoPerfil;
  final String bio;

  factory UsuarioResumo.fromJson(Map<String, dynamic> json) {
    return UsuarioResumo(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fotoPerfil: json['fotoPerfil'] as String?,
      bio: json['bio']?.toString() ?? '',
    );
  }
}
