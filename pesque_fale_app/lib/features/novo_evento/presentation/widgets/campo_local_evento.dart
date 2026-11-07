import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../providers/novo_evento_provider.dart';

class CampoLocalEvento extends StatefulWidget {
  const CampoLocalEvento({
    super.key,
    required this.ponto,
    required this.localTexto,
    required this.limite,
    required this.onEscolherPonto,
    required this.onRemoverPonto,
    required this.onLocalTexto,
    this.erro,
  });

  final PontoDoEvento? ponto;
  final String localTexto;
  final int limite;
  final VoidCallback onEscolherPonto;
  final VoidCallback onRemoverPonto;
  final ValueChanged<String> onLocalTexto;
  final String? erro;

  @override
  State<CampoLocalEvento> createState() => _CampoLocalEventoState();
}

class _CampoLocalEventoState extends State<CampoLocalEvento> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.localTexto,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textos = Theme.of(context).textTheme;
    final ponto = widget.ponto;

    if (ponto != null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: AppRadius.mdRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: colors.primaryAccent),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ponto.nome,
                        style: textos.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (ponto.regiao != null)
                        Text(
                          ponto.regiao!,
                          style: textos.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.xs,
              children: [
                TextButton(
                  onPressed: widget.onEscolherPonto,
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: const Text('Trocar ponto'),
                ),
                TextButton(
                  onPressed: widget.onRemoverPonto,
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: const Text('Escrever outro local'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: widget.onEscolherPonto,
          icon: Icon(Icons.location_on_outlined, color: colors.primaryAccent),
          label: Text(
            'Escolher um ponto da lista',
            style: TextStyle(color: colors.primaryAccent),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _controller,
          maxLength: widget.limite,
          onChanged: widget.onLocalTexto,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Ou escreva o local',
            hintText: 'Ex.: Lago Azul, Matão-SP',
            errorText: widget.erro,
            errorMaxLines: 2,
            border: OutlineInputBorder(borderRadius: AppRadius.mdRadius),
          ),
        ),
      ],
    );
  }
}
