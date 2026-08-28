import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// TODO(henrique): considerar mover para GET/PATCH /usuarios/me quando o backend suportar o campo
class OnboardingStatusStorage {
  OnboardingStatusStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _chave(String userId) => 'onboarding_concluido:$userId';

  Future<bool> isConcluido(String userId) async {
    final valor = await _storage.read(key: _chave(userId));
    return valor == 'true';
  }

  Future<void> marcarConcluido(String userId) =>
      _storage.write(key: _chave(userId), value: 'true');

  Future<void> limpar(String userId) =>
      _storage.delete(key: _chave(userId));
}
