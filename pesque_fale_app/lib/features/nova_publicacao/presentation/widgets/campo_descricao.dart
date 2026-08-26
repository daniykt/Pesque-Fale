import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class CampoDescricao extends StatefulWidget {
  const CampoDescricao({
    super.key,
    required this.valor,
    required this.onChanged,
    required this.limite,
  });

  final String valor;
  final ValueChanged<String> onChanged;
  final int limite;

  @override
  State<CampoDescricao> createState() => _CampoDescricaoState();
}

class _CampoDescricaoState extends State<CampoDescricao> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.valor,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descrição',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _controller,
          minLines: 4,
          maxLines: 6,
          maxLength: widget.limite,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: 'Conte como foi a pescaria, dicas do local...',
            border: OutlineInputBorder(
              borderRadius: AppRadius.mdRadius,
              borderSide: BorderSide(color: colors.border),
            ),
          ),
        ),
      ],
    );
  }
}
