import 'package:flutter/material.dart';

class ErroMutualFollowDialog extends StatelessWidget {
  const ErroMutualFollowDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Não é possível conversar'),
        content: const Text(
          'Vocês precisam se seguir mutuamente para conversar.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }
}
