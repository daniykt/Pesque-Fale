import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/username_check_state.dart';
import '../../../providers/editar_perfil_provider.dart';

class CampoUsername extends StatefulWidget {
  const CampoUsername({super.key});

  @override
  State<CampoUsername> createState() => _CampoUsernameState();
}

class _CampoUsernameState extends State<CampoUsername> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<EditarPerfilProvider>().username,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditarPerfilProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;

    if (_controller.text != provider.username) {
      _controller.value = TextEditingValue(
        text: provider.username,
        selection: TextSelection.collapsed(offset: provider.username.length),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Username', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _controller,
            onChanged: provider.onUsernameChanged,
            decoration: InputDecoration(
              prefixText: '@',
              suffixIcon: provider.usernameAlterado
                  ? IconButton(
                      icon: const Icon(Icons.undo),
                      tooltip: 'Restaurar username original',
                      onPressed: provider.resetUsername,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          _StatusUsername(state: provider.usernameState, colors: colors),
        ],
      ),
    );
  }
}

class _StatusUsername extends StatelessWidget {
  const _StatusUsername({required this.state, required this.colors});

  final UsernameCheckState state;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final (Widget? icone, Color? cor, String? texto) = switch (state) {
      UsernameCheckState.idle => (null, null, null),
      UsernameCheckState.validating => (
        const SizedBox(
          height: 14,
          width: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        colors.textSecondary,
        'Verificando...',
      ),
      UsernameCheckState.invalidoFormato => (
        Icon(Icons.error_outline, size: 16, color: colors.danger),
        colors.danger,
        '3-20 caracteres. Use letras, números, _ ou .',
      ),
      UsernameCheckState.indisponivel => (
        Icon(Icons.cancel_outlined, size: 16, color: colors.danger),
        colors.danger,
        'Já em uso',
      ),
      UsernameCheckState.disponivel => (
        Icon(Icons.check_circle_outline, size: 16, color: colors.success),
        colors.success,
        'Disponível',
      ),
      UsernameCheckState.atual => (
        Icon(Icons.check_circle_outline, size: 16, color: colors.success),
        colors.success,
        'Username atual',
      ),
    };

    if (texto == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icone!,
        const SizedBox(width: AppSpacing.xxs),
        Text(texto, style: TextStyle(color: cor, fontSize: 12)),
      ],
    );
  }
}
