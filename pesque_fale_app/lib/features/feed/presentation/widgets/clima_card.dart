import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../clima/data/localizacao_service.dart';
import '../../../clima/domain/clima.dart';
import '../../../clima/domain/condicao_clima.dart';
import '../../../clima/domain/data_por_extenso.dart';
import '../../../clima/providers/clima_provider.dart';

class ClimaCard extends StatelessWidget {
  const ClimaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final provider = context.watch<ClimaProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.mdRadius,
      ),
      child: switch (provider.status) {
        StatusClima.inicial => const _ClimaSkeleton(animar: false),
        StatusClima.carregando => const _ClimaSkeleton(animar: true),
        StatusClima.sucesso => _ClimaAtual(
          clima: provider.clima!,
          hoje: provider.hoje,
        ),
        StatusClima.semLocalizacao => _AvisoClima(
          icone: Icons.location_off_outlined,
          mensagem: _mensagemSemLocalizacao(provider.motivoSemLocalizacao),
          rotuloBotao: _rotuloSemLocalizacao(provider.motivoSemLocalizacao),
          onPressed: provider.permitirLocalizacao,
        ),
        StatusClima.erro => _AvisoClima(
          icone: Icons.cloud_off_outlined,
          mensagem:
              provider.mensagemErro ?? 'Não foi possível obter o clima agora.',
          rotuloBotao: 'Tentar de novo',
          onPressed: provider.atualizar,
        ),
      },
    );
  }

  static String _mensagemSemLocalizacao(MotivoSemLocalizacao? motivo) {
    switch (motivo) {
      case MotivoSemLocalizacao.servicoDesligado:
        return 'A localização do aparelho está desligada. Ative para ver o '
            'clima de onde você está.';
      case MotivoSemLocalizacao.negadaParaSempre:
        return 'O acesso à localização está bloqueado. Libere nas '
            'configurações do aparelho para ver o clima de onde você está.';
      case MotivoSemLocalizacao.negada:
      case null:
        return 'Permita o acesso à localização para ver o clima de onde '
            'você está.';
    }
  }

  static String _rotuloSemLocalizacao(MotivoSemLocalizacao? motivo) {
    switch (motivo) {
      case MotivoSemLocalizacao.servicoDesligado:
        return 'Ativar localização';
      case MotivoSemLocalizacao.negadaParaSempre:
        return 'Abrir configurações';
      case MotivoSemLocalizacao.negada:
      case null:
        return 'Permitir localização';
    }
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.icone, this.data});

  final IconData icone;
  final String? data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textos = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icone, color: colors.primaryAccent, size: 28),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clima agora',
                style: textos.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (data != null)
                Text(
                  data!,
                  style: textos.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClimaAtual extends StatelessWidget {
  const _ClimaAtual({required this.clima, required this.hoje});

  final Clima clima;
  final DateTime hoje;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Cabecalho(
          icone: _iconeDaCondicao(clima.condicao),
          data: dataPorExtenso(hoje),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${clima.temperatura.round()}°C',
          style: textos.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.primaryAccent,
          ),
        ),
        Text(clima.condicao.descricao, style: textos.titleMedium),
        const SizedBox(height: AppSpacing.md),
        _Medida(
          icone: Icons.air,
          texto: 'Vento: ${clima.ventoKmh.round()} km/h',
        ),
        const SizedBox(height: AppSpacing.xs),
        _Medida(
          icone: Icons.water_drop_outlined,
          texto: 'Umidade: ${clima.umidade}%',
        ),
      ],
    );
  }

  static IconData _iconeDaCondicao(CondicaoClima condicao) {
    switch (condicao) {
      case CondicaoClima.ceuLimpo:
        return Icons.wb_sunny_outlined;
      case CondicaoClima.poucasNuvens:
      case CondicaoClima.parcialmenteNublado:
        return Icons.wb_cloudy_outlined;
      case CondicaoClima.nublado:
        return Icons.cloud_outlined;
      case CondicaoClima.neblina:
        return Icons.foggy;
      case CondicaoClima.garoa:
      case CondicaoClima.chuva:
      case CondicaoClima.chuvaForte:
      case CondicaoClima.pancadasDeChuva:
        return Icons.water_drop_outlined;
      case CondicaoClima.neve:
        return Icons.ac_unit;
      case CondicaoClima.trovoada:
      case CondicaoClima.trovoadaComGranizo:
        return Icons.thunderstorm_outlined;
      case CondicaoClima.desconhecida:
        return Icons.help_outline;
    }
  }
}

class _Medida extends StatelessWidget {
  const _Medida({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Row(
      children: [
        Icon(icone, color: colors.textSecondary, size: 22),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(texto, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}

class _AvisoClima extends StatelessWidget {
  const _AvisoClima({
    required this.icone,
    required this.mensagem,
    required this.rotuloBotao,
    required this.onPressed,
  });

  final IconData icone;
  final String mensagem;
  final String rotuloBotao;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Cabecalho(icone: icone),
        const SizedBox(height: AppSpacing.sm),
        Text(mensagem, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            foregroundColor: colors.primaryAccent,
            side: BorderSide(color: colors.primaryAccent),
          ),
          child: Text(rotuloBotao),
        ),
      ],
    );
  }
}

class _ClimaSkeleton extends StatefulWidget {
  const _ClimaSkeleton({required this.animar});

  final bool animar;

  @override
  State<_ClimaSkeleton> createState() => _ClimaSkeletonState();
}

class _ClimaSkeletonState extends State<_ClimaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
    value: 0.5,
  );
  late final Animation<double> _opacidade = Tween<double>(
    begin: 0.4,
    end: 0.75,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _aplicarAnimacao();
  }

  @override
  void didUpdateWidget(_ClimaSkeleton antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.animar != widget.animar) _aplicarAnimacao();
  }

  void _aplicarAnimacao() {
    if (widget.animar) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    Widget bloco(double largura, double altura) => Container(
      width: largura,
      height: altura,
      decoration: BoxDecoration(
        color: colors.border,
        borderRadius: AppRadius.smRadius,
      ),
    );

    return Semantics(
      label: 'Carregando o clima',
      child: FadeTransition(
        opacity: _opacidade,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bloco(160, 20),
            const SizedBox(height: AppSpacing.sm),
            bloco(96, 44),
            const SizedBox(height: AppSpacing.xs),
            bloco(180, 18),
            const SizedBox(height: AppSpacing.md),
            bloco(140, 18),
            const SizedBox(height: AppSpacing.xs),
            bloco(140, 18),
          ],
        ),
      ),
    );
  }
}
