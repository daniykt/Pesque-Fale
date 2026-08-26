import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/comentarios_provider.dart';

class ComentarioInputBar extends StatefulWidget {
  const ComentarioInputBar({super.key, this.padding, this.focusNode});

  final EdgeInsetsGeometry? padding;
  final FocusNode? focusNode;

  @override
  State<ComentarioInputBar> createState() => _ComentarioInputBarState();
}

class _ComentarioInputBarState extends State<ComentarioInputBar> {
  final _controller = TextEditingController();
  bool _temTexto = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final temTexto = _controller.text.trim().isNotEmpty;
      if (temTexto != _temTexto) setState(() => _temTexto = temTexto);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: widget.padding ?? const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: widget.focusNode,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Adicione um comentário...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.send,
                color: _temTexto ? colors.primary : colors.textSecondary,
              ),
              onPressed: _temTexto ? _enviar : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.usuario == null) {
      AppSnackbar.showInfo(context, 'Faça login para comentar');
      return;
    }

    _controller.clear();
    try {
      await context.read<ComentariosProvider>().enviar(texto);
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(context, 'Não foi possível enviar');
        _controller.text = texto;
      }
    }
  }
}
