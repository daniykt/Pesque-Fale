class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.username,
    this.fotoPerfil,
    this.banner,
    this.bio,
    this.localizacao,
    required this.onboardingConcluido,
    this.seguidores = 0,
    this.seguindo = 0,
    this.criadoEm,
  });

  final String id;
  final String nome;
  final String email;
  final String? username;
  final String? fotoPerfil;
  final String? banner;
  final String? bio;
  final String? localizacao;
  final bool onboardingConcluido;
  final int seguidores;
  final int seguindo;
  final String? criadoEm;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username'] as String?,
      fotoPerfil: json['fotoPerfil'] as String?,
      banner: json['banner'] as String?,
      bio: json['bio'] as String?,
      localizacao: json['localizacao'] as String?,
      onboardingConcluido: json['onboardingConcluido'] as bool? ?? false,
      seguidores: json['seguidores'] as int? ?? 0,
      seguindo: json['seguindo'] as int? ?? 0,
      criadoEm: json['criadoEm']?.toString(),
    );
  }
}
