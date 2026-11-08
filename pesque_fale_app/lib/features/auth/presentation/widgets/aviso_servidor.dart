import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/servidor/servidor_status_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Aviso discreto, acima do botão principal, enquanto a API acorda.
///
/// Só o texto do estado fica na região viva: o contador de segundos muda a
/// cada segundo e o leitor de tela não deve anunciá-lo sozinho.
class AvisoServidorBanner extends StatelessWidget {
  const AvisoServidorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final servidor = context.watch<ServidorStatusProvider>();
    final aviso = servidor.aviso;
    if (aviso == AvisoServidor.nenhum) return const SizedBox.shrink();

    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final estilo = textTheme.bodyMedium?.copyWith(color: colors.textPrimary);
    final estiloSecundario = textTheme.bodyMedium?.copyWith(
      color: colors.textSecondary,
    );

    final (IconData icone, Color corIcone) = switch (aviso) {
      AvisoServidor.pronto => (Icons.cloud_done_outlined, colors.success),
      AvisoServidor.falhou => (Icons.cloud_off_outlined, colors.danger),
      _ => (Icons.cloud_outlined, colors.primaryAccent),
    };

    final List<Widget> conteudo = switch (aviso) {
      AvisoServidor.pronto => [
        Semantics(
          liveRegion: true,
          child: Text('Servidor pronto', style: estilo),
        ),
      ],
      AvisoServidor.falhou => [
        Semantics(
          liveRegion: true,
          child: Text('Não foi possível conectar ao servidor.', style: estilo),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: servidor.tentarDeNovo,
            style: TextButton.styleFrom(
              foregroundColor: colors.primaryAccent,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            ),
            child: const Text('Tentar de novo'),
          ),
        ),
      ],
      _ => [
        Wrap(
          spacing: AppSpacing.xxs,
          children: [
            Semantics(
              liveRegion: true,
              child: Text('Conectando ao servidor…', style: estilo),
            ),
            Semantics(
              label: '${servidor.segundosDecorridos} segundos',
              excludeSemantics: true,
              child: Text('${servidor.segundosDecorridos}s', style: estilo),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Na primeira vez do dia pode levar até 1 minuto.',
          style: estiloSecundario,
        ),
      ],
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        key: const ValueKey('aviso-servidor'),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: corIcone),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: conteudo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
