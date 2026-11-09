import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/feed/data/publicacoes_repository.dart';
import '../../features/feed/domain/publicacao.dart';
import '../../features/feed/providers/publicacoes_store.dart';
import '../../features/visualizacao_post/presentation/publicacao_detalhe_page.dart';
import '../../features/visualizacao_post/providers/publicacao_detalhe_provider.dart';

/// Nome da rota do detalhe da publicação.
const rotaDetalhePublicacaoNome = '/publicacao/detalhe';

/// Monta a rota do detalhe da publicação. Usada pelo `onGenerateRoute` do
/// `main.dart` e pelos testes, para os dois abrirem o detalhe do mesmo jeito.
///
/// Aceita como argumento a [Publicacao] já hidratada (feed, perfil) ou só o
/// id (notificação). Devolve `null` para outra rota ou argumento inválido.
Route<dynamic>? rotaDetalhePublicacao(RouteSettings settings) {
  if (settings.name != rotaDetalhePublicacaoNome) return null;

  final args = settings.arguments;
  final Publicacao? publicacaoInicial = args is Publicacao ? args : null;
  final String? publicacaoId = args is String ? args : null;
  if (publicacaoInicial == null && publicacaoId == null) return null;

  return MaterialPageRoute(
    builder: (context) => ChangeNotifierProvider<PublicacaoDetalheProvider>(
      create: (ctx) => PublicacaoDetalheProvider(
        publicacoesRepository: ctx.read<PublicacoesRepository>(),
        store: ctx.read<PublicacoesStore>(),
        publicacaoInicial: publicacaoInicial,
        publicacaoId: publicacaoId,
      )..carregar(),
      child: const PublicacaoDetalhePage(),
    ),
  );
}
