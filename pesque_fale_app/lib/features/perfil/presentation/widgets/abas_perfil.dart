import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/publicacao.dart';
import 'aba_em_breve.dart';
import 'galeria_perfil.dart';

class AbasPerfil extends StatefulWidget {
  const AbasPerfil({
    super.key,
    required this.publicacoes,
    required this.isOwnProfile,
  });

  final List<Publicacao> publicacoes;
  final bool isOwnProfile;

  @override
  State<AbasPerfil> createState() => _AbasPerfilState();
}

class _AbasPerfilState extends State<AbasPerfil>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      children: [
        TabBar(
          controller: _controller,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          tabs: const [
            Tab(text: 'Galeria'),
            Tab(text: 'Equipamentos'),
            Tab(text: 'Locais Salvos'),
          ],
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.index != 0) return const AbaEmBreve();
            return GaleriaPerfil(
              publicacoes: widget.publicacoes,
              isOwnProfile: widget.isOwnProfile,
            );
          },
        ),
      ],
    );
  }
}
