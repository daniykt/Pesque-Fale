import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/editar_perfil_provider.dart';
import '../../providers/perfil_provider.dart';
import 'widgets/botao_salvar.dart';
import 'widgets/campo_banner.dart';
import 'widgets/campo_foto.dart';
import 'widgets/campo_username.dart';
import 'widgets/contador_bio.dart';
import 'widgets/editar_secao.dart';

class EditarPerfilPage extends StatelessWidget {
  const EditarPerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditarPerfilProvider>(
      create: (ctx) => EditarPerfilProvider(
        repository: ctx.read<PerfilProvider>().repository,
        authProvider: ctx.read<AuthProvider>(),
      ),
      child: const _EditarPerfilView(),
    );
  }
}

class _EditarPerfilView extends StatefulWidget {
  const _EditarPerfilView();

  @override
  State<_EditarPerfilView> createState() => _EditarPerfilViewState();
}

class _EditarPerfilViewState extends State<_EditarPerfilView> {
  late final TextEditingController _nomeController;
  late final TextEditingController _bioController;
  late final TextEditingController _localizacaoController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<EditarPerfilProvider>();
    _nomeController = TextEditingController(text: provider.nome);
    _bioController = TextEditingController(text: provider.bio);
    _localizacaoController = TextEditingController(text: provider.localizacao);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _bioController.dispose();
    _localizacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditarPerfilProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const CampoBanner(),
                  Positioned(
                    left: AppSpacing.sm,
                    bottom: -32,
                    child: const CampoFoto(),
                  ),
                ],
              ),
              const SizedBox(height: 32 + AppSpacing.md),
              EditarSecao(
                label: 'Nome',
                dica: 'Mínimo de 2 caracteres.',
                child: TextField(
                  controller: _nomeController,
                  onChanged: provider.onNomeChanged,
                  decoration: InputDecoration(
                    errorText: provider.fieldErrors['nome'],
                  ),
                ),
              ),
              const CampoUsername(),
              EditarSecao(
                label: 'Localização',
                child: TextField(
                  controller: _localizacaoController,
                  onChanged: provider.onLocalizacaoChanged,
                ),
              ),
              EditarSecao(
                label: 'Bio',
                child: TextField(
                  controller: _bioController,
                  onChanged: provider.onBioChanged,
                  maxLines: 4,
                  maxLength: 300,
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                ),
              ),
              ContadorBio(tamanhoAtual: provider.bio.length),
              const SizedBox(height: AppSpacing.lg),
              const BotaoSalvar(),
            ],
          ),
        ),
      ),
    );
  }
}
