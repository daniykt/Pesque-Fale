import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../widgets/auth_hero.dart';
import '../widgets/auth_logo_title.dart';
import '../widgets/auth_password_field.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_switch_link.dart';
import '../widgets/auth_underline_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    await auth.login(
      email: _emailController.text.trim(),
      senha: _senhaController.text,
    );

    if (!mounted) return;

    if (auth.status == AuthStatus.success) {
      final usuario = auth.usuario!;
      if (usuario.onboardingConcluido) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.status == AuthStatus.loading;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHero(collapsed: keyboardOpen),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthLogoTitle(title: 'Entrar'),
                    AuthUnderlineField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AuthPasswordField(
                      controller: _senhaController,
                      label: 'Senha',
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: null,
                        child: Text(
                          'Esqueci minha senha',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AuthPrimaryButton(
                      label: 'Entrar',
                      onPressed: isLoading ? null : _login,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AuthSwitchLink(
                      question: 'Não tem conta? ',
                      actionLabel: 'Cadastre-se',
                      onTap: () => Navigator.of(
                        context,
                      ).pushReplacementNamed('/cadastro'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}