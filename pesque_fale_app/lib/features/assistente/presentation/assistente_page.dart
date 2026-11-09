import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/servico_voz.dart';
import '../data/servico_voz_dispositivo.dart';
import '../providers/assistente_provider.dart';
import '../providers/voz_provider.dart';
import 'navegacao_assistente.dart';
import 'widgets/balao_mensagem.dart';
import 'widgets/boas_vindas_assistente.dart';
import 'widgets/campo_pergunta.dart';
import 'widgets/mascote_pira.dart';

class AssistentePage extends StatelessWidget {
  const AssistentePage({super.key, this.servicoVoz});

  final ServicoVoz? servicoVoz;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          VozProvider(servico: servicoVoz ?? ServicoVozDispositivo()),
      child: const _TelaAssistente(),
    );
  }
}

class _TelaAssistente extends StatelessWidget {
  const _TelaAssistente();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssistenteProvider>();
    final aviso = context.select<VozProvider, String?>((voz) => voz.aviso);
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            MascotePira(tamanho: 32, cor: Colors.white),
            SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(MascotePira.nome),
                Text(
                  'assistente virtual',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const _AvisoAssistenteVirtual(),
          Expanded(
            child: provider.conversaVazia && !provider.enviando
                ? BoasVindasAssistente(
                    sugestoes: AssistenteProvider.sugestoes,
                    onSugestao: provider.enviar,
                  )
                : _Conversa(provider: provider),
          ),
          if (aviso != null) _AvisoVoz(texto: aviso),
          CampoPergunta(
            habilitado: !provider.enviando,
            onEnviar: provider.enviar,
          ),
        ],
      ),
    );
  }
}

class _AvisoAssistenteVirtual extends StatelessWidget {
  const _AvisoAssistenteVirtual();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: colors.surfaceVariant,
      child: Text(
        'O ${MascotePira.nome} é um assistente virtual e pode errar. Confira as informações importantes.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

class _AvisoVoz extends StatelessWidget {
  const _AvisoVoz({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        color: colors.surfaceVariant,
        child: Row(
          children: [
            Icon(Icons.mic_off_outlined, color: colors.danger),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                texto,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  color: colors.danger,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Conversa extends StatelessWidget {
  const _Conversa({required this.provider});

  final AssistenteProvider provider;

  @override
  Widget build(BuildContext context) {
    final voz = context.watch<VozProvider>();
    final mensagens = provider.mensagens.reversed.toList();
    final temRodape = provider.enviando || provider.erro != null;

    return ListView.separated(
      reverse: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: mensagens.length + (temRodape ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (temRodape && index == 0) {
          return provider.enviando
              ? _Pensando(demorando: provider.demorando)
              : _ErroResposta(
                  mensagem: provider.erro!,
                  onTentarDeNovo: provider.tentarDeNovo,
                );
        }
        final mensagem = mensagens[index - (temRodape ? 1 : 0)];
        return BalaoMensagem(
          mensagem: mensagem,
          onAcao: (acao) => abrirAcaoDoAssistente(context, acao),
          lendo: voz.estaLendo(mensagem),
          onOuvir: mensagem.doUsuario
              ? null
              : () => voz.alternarLeitura(mensagem),
        );
      },
    );
  }
}

class _Pensando extends StatelessWidget {
  const _Pensando({required this.demorando});

  final bool demorando;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final estilo = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontSize: 17,
      color: colors.textSecondary,
    );

    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          const MascotePira(tamanho: 32, animando: true),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              demorando
                  ? 'Acordando o ${MascotePira.nome}... a primeira resposta pode levar até 1 minuto.'
                  : 'O ${MascotePira.nome} está pensando...',
              style: estilo,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErroResposta extends StatelessWidget {
  const _ErroResposta({required this.mensagem, required this.onTentarDeNovo});

  final String mensagem;
  final VoidCallback onTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mensagem,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 17,
              color: colors.danger,
            ),
          ),
          TextButton.icon(
            onPressed: onTentarDeNovo,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar de novo'),
          ),
        ],
      ),
    );
  }
}