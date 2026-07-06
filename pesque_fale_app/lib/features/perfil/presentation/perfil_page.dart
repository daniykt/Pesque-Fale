import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/perfil_provider.dart';
import 'widgets/abas_perfil.dart';
import 'widgets/cabecalho_perfil.dart';
import 'widgets/cta_perfil.dart';
import 'widgets/estatisticas_perfil.dart';
import 'widgets/perfil_opcoes_sheet.dart';
import 'widgets/perfil_skeleton.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() async {
    final id = context.read<AuthProvider>().usuario?.id;
    if (id == null) return;
    await context.read<PerfilProvider>().carregarPerfil(id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PerfilProvider>();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _carregar,
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(PerfilProvider provider) {
    if (provider.status == PerfilStatus.loading ||
        provider.status == PerfilStatus.idle) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: PerfilSkeleton(),
      );
    }

    if (provider.status == PerfilStatus.error || provider.perfil == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text(
                  provider.errorMessage ??
                      'Não foi possível carregar o perfil.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: _carregar,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final usuario = provider.perfil!;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabecalhoPerfil(
            usuario: usuario,
            isOwnProfile: provider.isOwnProfile,
            onEditar: () => Navigator.pushNamed(context, '/perfil/editar'),
            onMenu: () => PerfilOpcoesSheet.show(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: EstatisticasPerfil(
              usuario: usuario,
              totalPublicacoes: provider.totalPublicacoes,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: const CtaPerfil(),
          ),
          AbasPerfil(
            publicacoes: provider.publicacoes,
            isOwnProfile: provider.isOwnProfile,
          ),
        ],
      ),
    );
  }
}
