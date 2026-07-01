import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

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
                    AuthPrimaryButton(label: 'Entrar', onPressed: () {}),
                    const SizedBox(height: AppSpacing.sm),
                    AuthSwitchLink(
                      question: 'Não tem conta? ',
                      actionLabel: 'Cadastre-se',
                      onTap: () =>
                          Navigator.of(context).pushReplacementNamed('/cadastro'),
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
