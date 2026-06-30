import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/senha_field.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  AuthStatus _lastStatus = AuthStatus.idle;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  String? _validarNome(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'O nome deve ter pelo menos 2 caracteres.';
    }
    return null;
  }

  String? _validarEmail(String? value) {
    if (value == null || !_emailRegex.hasMatch(value.trim())) {
      return 'Informe um email válido.';
    }
    return null;
  }

  String? _validarSenha(String? value) {
    if (value == null || value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    return null;
  }

  String? _validarConfirmarSenha(String? value) {
    if (value != _senhaController.text) {
      return 'As senhas não conferem.';
    }
    return null;
  }

  void _submit() {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    if (!_formKey.currentState!.validate()) return;

    auth.cadastrar(
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      senha: _senhaController.text,
      confirmarSenha: _confirmarSenhaController.text,
    );
  }

  void _handleStatusChange(AuthProvider auth) {
    if (auth.status == _lastStatus) return;
    final novoStatus = auth.status;
    _lastStatus = novoStatus;

    if (novoStatus == AuthStatus.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/onboarding');
      });
    } else if (novoStatus == AuthStatus.error && auth.fieldErrors.isEmpty && auth.errorMessage != null) {
      final mensagem = auth.errorMessage!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    _handleStatusChange(auth);
    final isLoading = auth.status == AuthStatus.loading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pesque & Fale',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Crie sua conta',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                AuthTextField(
                  controller: _nomeController,
                  labelText: 'Nome',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: _validarNome,
                  serverErrorText: auth.fieldErrors['nome'],
                  onChanged: (_) => auth.clearError(),
                ),
                const SizedBox(height: AppSpacing.md),
                AuthTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validarEmail,
                  serverErrorText: auth.fieldErrors['email'],
                  onChanged: (_) => auth.clearError(),
                ),
                const SizedBox(height: AppSpacing.md),
                SenhaField(
                  controller: _senhaController,
                  labelText: 'Senha',
                  textInputAction: TextInputAction.next,
                  validator: _validarSenha,
                  serverErrorText: auth.fieldErrors['senha'],
                  onChanged: (_) => auth.clearError(),
                ),
                const SizedBox(height: AppSpacing.md),
                SenhaField(
                  controller: _confirmarSenhaController,
                  labelText: 'Confirmar senha',
                  textInputAction: TextInputAction.done,
                  validator: _validarConfirmarSenha,
                  serverErrorText: auth.fieldErrors['confirmarSenha'],
                  onChanged: (_) => auth.clearError(),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Ao criar conta, você aceita os Termos e a Política de Privacidade',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Criar conta'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                  child: const Text('Já tem uma conta? Entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
