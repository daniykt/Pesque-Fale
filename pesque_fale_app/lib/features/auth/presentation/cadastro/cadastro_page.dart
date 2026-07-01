import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../providers/auth_provider.dart';
import '../widgets/auth_hero.dart';
import '../widgets/auth_logo_title.dart';
import '../widgets/auth_password_field.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_switch_link.dart';
import '../widgets/auth_underline_field.dart';

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

  String? _validarNome(String? v) => (v == null || v.trim().length < 2)
      ? 'O nome deve ter pelo menos 2 caracteres.'
      : null;

  String? _validarEmail(String? v) =>
      (v == null || !_emailRegex.hasMatch(v.trim()))
      ? 'Informe um email válido.'
      : null;

  String? _validarSenha(String? v) => (v == null || v.length < 6)
      ? 'A senha deve ter pelo menos 6 caracteres.'
      : null;

  String? _validarConfirmarSenha(String? v) =>
      v != _senhaController.text ? 'As senhas não conferem.' : null;

  void _submit(AuthProvider auth) {
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
    _lastStatus = auth.status;

    if (auth.status == AuthStatus.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/onboarding');
      });
    } else if (auth.status == AuthStatus.error &&
        auth.fieldErrors.isEmpty &&
        auth.errorMessage != null) {
      final msg = auth.errorMessage!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppSnackbar.showError(context, msg);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        _handleStatusChange(auth);
        final isLoading = auth.status == AuthStatus.loading;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: colors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHero(collapsed: keyboardOpen),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthLogoTitle(title: 'Cadastro'),
                          AuthUnderlineField(
                            controller: _nomeController,
                            label: 'Nome',
                            icon: Icons.person_outline,
                            textInputAction: TextInputAction.next,
                            validator: _validarNome,
                            serverErrorText: auth.fieldErrors['nome'],
                            onChanged: (_) => auth.clearError(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AuthUnderlineField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.alternate_email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: _validarEmail,
                            serverErrorText: auth.fieldErrors['email'],
                            onChanged: (_) => auth.clearError(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AuthPasswordField(
                            controller: _senhaController,
                            label: 'Senha',
                            textInputAction: TextInputAction.next,
                            validator: _validarSenha,
                            serverErrorText: auth.fieldErrors['senha'],
                            onChanged: (_) => auth.clearError(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AuthPasswordField(
                            controller: _confirmarSenhaController,
                            label: 'Confirmar Senha',
                            textInputAction: TextInputAction.done,
                            validator: _validarConfirmarSenha,
                            serverErrorText: auth.fieldErrors['confirmarSenha'],
                            onChanged: (_) => auth.clearError(),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AuthPrimaryButton(
                            label: 'Cadastrar',
                            loading: isLoading,
                            onPressed: () => _submit(auth),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AuthSwitchLink(
                            question: 'Já tem conta? ',
                            actionLabel: 'Entrar',
                            onTap: () => Navigator.of(
                              context,
                            ).pushReplacementNamed('/login'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Ao criar conta, você aceita os Termos e a Política de Privacidade.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
