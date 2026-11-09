import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

class BuscaConversasBar extends StatefulWidget {
  const BuscaConversasBar({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<BuscaConversasBar> createState() => _BuscaConversasBarState();
}

class _BuscaConversasBarState extends State<BuscaConversasBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _limpar() {
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return TextField(
      controller: _controller,
      onChanged: (valor) {
        widget.onChanged(valor);
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: 'Buscar conversa...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.close), onPressed: _limpar)
            : null,
        filled: true,
        fillColor: colors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: AppRadius.pillRadius,
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
