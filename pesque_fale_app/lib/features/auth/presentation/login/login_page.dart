import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../core/config/app_config.dart';
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
        Navigator.of(context).pushReplacementNamed('/entrando');
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    } else if (auth.errorMessage != null) {
      AppSnackbar.showError(context, auth.errorMessage!);
    }
  }

  // DEBUG temporario: testa a conexao com a API.
  Future<String> _executarTesteConexao(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 60));
      final body = response.body;
      final trecho = body.length > 200 ? body.substring(0, 200) : body;
      return 'Status: ${response.statusCode}\n\nBody (200 chars):\n$trecho';
    } catch (e) {
      return 'Exception: ${e.runtimeType}\n\n$e';
    }
  }

  void _testarConexao() {
    final url = '${AppConfig.apiBaseUrl}/pontos';
    final resultado = _executarTesteConexao(url);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Testar Conexão'),
        content: SingleChildScrollView(
          child: FutureBuilder<String>(
            future: resultado,
            builder: (context, snapshot) => SelectableText(
              'URL: $url\n\n${snapshot.data ?? 'Aguardando resposta (até 60s)...'}',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
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
                    // DEBUG temporario: remover antes da entrega.
                    OutlinedButton(
                      onPressed: _testarConexao,
                      child: const Text('🔧 Testar Conexão'),
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
