import 'package:flutter/foundation.dart';

import '../data/auth_exceptions.dart';
import '../data/auth_repository.dart';
import '../domain/usuario.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.repository});

  final AuthRepository repository;

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  Map<String, String> _fieldErrors = const {};
  Usuario? _usuario;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Map<String, String> get fieldErrors => _fieldErrors;
  Usuario? get usuario => _usuario;

  Future<void> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) async {
    _setLoading();
    try {
      final result = await repository.cadastrar(
        nome: nome,
        email: email,
        senha: senha,
        confirmarSenha: confirmarSenha,
      );
      _setSuccess(result.usuario);
    } on ValidationException catch (e) {
      _setValidationError(e);
    } on AuthException catch (e) {
      _setError(e.message);
    }
  }

  Future<void> login({required String email, required String senha}) async {
    _setLoading();
    try {
      final result = await repository.login(email: email, senha: senha);
      _setSuccess(result.usuario);
    } on ValidationException catch (e) {
      _setValidationError(e);
    } on AuthException catch (e) {
      _setError(e.message);
    }
  }

  Future<void> signOut() async {
    await repository.logout();
    _usuario = null;
    _status = AuthStatus.idle;
    _errorMessage = null;
    _fieldErrors = const {};
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _fieldErrors = const {};
    if (_status == AuthStatus.error) _status = AuthStatus.idle;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _fieldErrors = const {};
    notifyListeners();
  }

  void _setSuccess(Usuario usuario) {
    _usuario = usuario;
    _status = AuthStatus.success;
    notifyListeners();
  }

  void _setValidationError(ValidationException e) {
    _fieldErrors = e.fieldErrors;
    _errorMessage = e.message;
    _status = AuthStatus.error;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = AuthStatus.error;
    notifyListeners();
  }
}
