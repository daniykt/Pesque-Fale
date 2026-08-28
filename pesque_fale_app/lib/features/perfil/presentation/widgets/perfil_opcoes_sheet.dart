import 'package:flutter/material.dart';

/// Substitui o AppDrawer quando o usuário está vendo o próprio perfil.
class PerfilOpcoesSheet extends StatelessWidget {
  const PerfilOpcoesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => const PerfilOpcoesSheet(),
    );
  }

  void _sobreNos(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/sobre');
  }

  void _configuracoes(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/configuracoes');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('Sobre Nós'),
            onTap: () => _sobreNos(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configurações'),
            onTap: () => _configuracoes(context),
          ),
        ],
      ),
    );
  }
}
