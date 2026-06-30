import 'usuario.dart';

class AuthResult {
  const AuthResult({required this.accessToken, required this.usuario});

  final String accessToken;
  final Usuario usuario;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['access_token']?.toString() ?? '',
      usuario: Usuario.fromJson(
        (json['usuario'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}
