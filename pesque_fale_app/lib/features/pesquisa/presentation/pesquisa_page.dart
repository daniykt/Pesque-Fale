import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../auth/data/token_storage.dart';
import '../data/pontos_api_client.dart';
import '../data/pontos_repository.dart';
import '../data/pontos_repository_http.dart';
import '../data/pontos_repository_mock.dart';
import '../data/usuarios_busca_api_client.dart';
import '../data/usuarios_busca_repository.dart';
import '../data/usuarios_busca_repository_http.dart';
import '../data/usuarios_busca_repository_mock.dart';
import '../providers/pesquisa_locais_provider.dart';
import '../providers/pesquisa_usuarios_provider.dart';
import 'tabs/locais_tab.dart';
import 'tabs/usuarios_tab.dart';

class PesquisaPage extends StatelessWidget {
  const PesquisaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = TokenStorage();

    final PontosRepository pontosRepository = AppConfig.useMock
        ? PontosRepositoryMock()
        : PontosRepositoryHttp(
            apiClient: PontosApiClient(
              baseUrl: AppConfig.apiBaseUrl,
              tokenStorage: tokenStorage,
            ),
          );

    final UsuariosBuscaRepository usuariosBuscaRepository = AppConfig.useMock
        ? UsuariosBuscaRepositoryMock()
        : UsuariosBuscaRepositoryHttp(
            apiClient: UsuariosBuscaApiClient(
              baseUrl: AppConfig.apiBaseUrl,
              tokenStorage: tokenStorage,
            ),
          );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              PesquisaLocaisProvider(repository: pontosRepository)
                ..inicializar(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              PesquisaUsuariosProvider(repository: usuariosBuscaRepository),
        ),
      ],
      child: const _PesquisaView(),
    );
  }
}

class _PesquisaView extends StatelessWidget {
  const _PesquisaView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pesquisar'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Usuários'),
              Tab(icon: Icon(Icons.place), text: 'Locais'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [UsuariosTab(), LocaisTab()],
        ),
      ),
    );
  }
}
