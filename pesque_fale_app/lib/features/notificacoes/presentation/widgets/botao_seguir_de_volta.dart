import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class BotaoSeguirDeVolta extends StatefulWidget {
  const BotaoSeguirDeVolta({
    super.key,
    required this.jaSigo,
    required this.onSeguir,
  });

  final bool jaSigo;
  final Future<bool> Function() onSeguir;

  @override
  State<BotaoSeguirDeVolta> createState() => _BotaoSeguirDeVoltaState();
}

class _BotaoSeguirDeVoltaState extends State<BotaoSeguirDeVolta> {
  bool _carregando = false;
  late bool _jaSigo = widget.jaSigo;

  Future<void> _onTap() async {
    if (_carregando || _jaSigo) return;
    setState(() => _carregando = true);
    final sucesso = await widget.onSeguir();
    if (!mounted) return;
    setState(() {
      _carregando = false;
      if (sucesso) _jaSigo = true;
    });
    if (!sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível seguir agora.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      onTap: _onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _jaSigo ? colors.primary : Colors.transparent,
          border: Border.all(color: colors.primary),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: _carregando
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _jaSigo ? Colors.white : colors.primary,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _jaSigo ? Icons.check : Icons.person_add,
                      size: 14,
                      color: _jaSigo ? Colors.white : colors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _jaSigo ? 'Seguindo' : 'Seguir de volta',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _jaSigo ? Colors.white : colors.primary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
