import 'package:flutter/foundation.dart';

import '../data/auth_exceptions.dart';
import '../data/auth_repository.dart';
import '../domain/usuario.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthRepository repository}) : _repository = repository;

  final AuthRepository _repository;

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
    _status = AuthStatus.loading;
    _errorMessage = null;
    _fieldErrors = const {};
    notifyListeners();

    try {
      final result = await _repository.cadastrar(
        nome: nome,
        email: email,
        senha: senha,
        confirmarSenha: confirmarSenha,
      );
      _usuario = result.usuario;
      _status = AuthStatus.success;
      notifyListeners();
    } on ValidationException catch (e) {
      _fieldErrors = {for (final erro in e.errors) erro.campo: erro.mensagem};
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    _fieldErrors = const {};
    if (_status == AuthStatus.error) {
      _status = AuthStatus.idle;
    }
    notifyListeners();
  }
}
