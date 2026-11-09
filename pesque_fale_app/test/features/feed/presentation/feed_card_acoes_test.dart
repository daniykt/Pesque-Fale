import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/router/rota_detalhe_publicacao.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/assistente/presentation/widgets/botao_ajuda_assistente.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/clima/data/clima_repository.dart';
import 'package:pesque_fale_app/features/clima/data/localizacao_service.dart';
import 'package:pesque_fale_app/features/clima/domain/clima.dart';
import 'package:pesque_fale_app/features/clima/domain/condicao_clima.dart';
import 'package:pesque_fale_app/features/clima/providers/clima_provider.dart';
import 'package:pesque_fale_app/features/feed/data/comentarios_repository.dart';
import 'package:pesque_fale_app/features/feed/data/publicacoes_repository.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/presentation/feed_page.dart';
import 'package:pesque_fale_app/features/feed/presentation/widgets/acoes_bar.dart';
import 'package:pesque_fale_app/features/feed/presentation/widgets/publicacao_card.dart';
import 'package:pesque_fale_app/features/feed/providers/feed_provider.dart';
import 'package:pesque_fale_app/features/feed/providers/publicacoes_store.dart';
import 'package:pesque_fale_app/features/visualizacao_post/presentation/publicacao_detalhe_page.dart';
import 'package:pesque_fale_app/features/visualizacao_post/presentation/widgets/foto_publicacao.dart';
import 'package:pesque_fale_app/features/visualizacao_post/providers/publicacao_detalhe_provider.dart';

import '../../perfil/support/fakes_perfil_detalhe.dart';

/// A aba Dicas fica montada no IndexedStack e lê o ClimaProvider.
class _ClimaRepository implements ClimaRepository {
  @override
  Future<Clima> buscarAtual({
    required double latitude,
    required double longitude,
  }) async => const Clima(
    temperatura: 21.6,
    umidade: 83,
    ventoKmh: 7.2,
    condicao: CondicaoClima.chuva,
  );
}

class _Localizacao implements LocalizacaoService {
  @override
  Future<ResultadoLocalizacao> obter({required bool pedirPermissao}) async =>
      const LocalizacaoObtida(latitude: -21.6, longitude: -48.36);

  @override
  Future<void> abrirConfiguracoes(MotivoSemLocalizacao motivo) async {}
}

const _fotoUrl = 'https://res.cloudinary.com/demo/image/upload/v1/p.jpg';

Publicacao _post(
  String id, {
  String autorId = 'bruno',
  String autorNome = 'Bruno Pescador',
  String? descricao,
  String? imagemUrl = _fotoUrl,
  String? localTexto = 'Represa de Ibitinga',
  List<String> tags = const ['tucunare'],
  int curtidasCount = 3,
  int dia = 1,
}) => Publicacao(
  id: id,
  autorId: autorId,
  autorNome: autorNome,
  autorUsername: autorId,
  descricao: descricao ?? 'Pescaria $id na represa.',
  imagemUrl: imagemUrl,
  localTexto: localTexto,
  tags: tags,
  curtidasCount: curtidasCount,
  comentariosCount: 2,
  criadoEm: DateTime(2026, 1, dia),
  atualizadoEm: DateTime(2026, 1, dia),
);

/// O card pelos widgets reais: a FeedPage, a rota do detalhe do app e o
/// botão "Ajuda" expandido sobre a lista, como no MainShell.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const canalShare = MethodChannel('dev.fluttercommunity.plus/share');
  final compartilhados = <String>[];

  setUp(() {
    compartilhados.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalShare, (chamada) async {
          compartilhados.add((chamada.arguments as Map)['text'] as String);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalShare, null);
  });

  late FakeCurtidasRepository curtidas;

  void telaDeCelular(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Route<dynamic>? rotas(RouteSettings settings) {
    final detalhe = rotaDetalhePublicacao(settings);
    if (detalhe != null) return detalhe;
    if (settings.name == '/perfil' || settings.name == '/assistente') {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) =>
            Scaffold(body: Text('ROTA ${settings.name} ${settings.arguments}')),
      );
    }
    return null;
  }

  Future<void> montarFeed(
    WidgetTester tester,
    List<Publicacao> posts, {
    ThemeData? tema,
  }) async {
    final auth = await authLogado();
    final store = PublicacoesStore();
    final repo = FakePublicacoesRepository(feed: posts);
    curtidas = FakeCurtidasRepository();
    final feed = criarFeedProvider(
      publicacoesRepo: repo,
      curtidasRepo: curtidas,
      authProvider: auth,
      store: store,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<PublicacoesStore>.value(value: store),
          ChangeNotifierProvider<FeedProvider>.value(value: feed),
          Provider<PublicacoesRepository>.value(value: repo),
          ChangeNotifierProvider<ClimaProvider>(
            create: (_) => ClimaProvider(
              repository: _ClimaRepository(),
              localizacao: _Localizacao(),
            ),
          ),
          Provider<ComentariosRepository>.value(
            value: FakeComentariosRepository(),
          ),
        ],
        child: MaterialApp(
          theme: tema ?? AppTheme.light,
          onGenerateRoute: rotas,
          // Como no MainShell: o "Ajuda" flutua sobre a FeedPage. Expandido,
          // que é o caso em que ele ocupa mais espaço.
          home: const Scaffold(
            body: FeedPage(),
            floatingActionButton: BotaoAjudaAssistente(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder card(String id) => find.byKey(ValueKey(id));

  Finder noCard(String id, Finder finder) =>
      find.descendant(of: card(id), matching: finder);

  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  group('toques no card', () {
    for (final (nome, alvo) in [
      ('no texto', find.text('Pescaria p1 na represa.')),
      ('nas tags', find.text('#tucunare')),
      ('na foto', find.byType(FotoPublicacao)),
    ]) {
      testWidgets('tocar $nome abre o detalhe daquela publicação', (
        tester,
      ) async {
        await montarFeed(tester, [_post('p1')]);

        await tocar(tester, noCard('p1', alvo));

        expect(find.byType(PublicacaoDetalhePage), findsOneWidget);
        final detalhe = Provider.of<PublicacaoDetalheProvider>(
          tester.element(find.byType(PublicacaoDetalhePage)),
          listen: false,
        );
        expect(detalhe.publicacao?.id, 'p1');
      });
    }

    testWidgets('tocar no autor abre o perfil, não o detalhe', (tester) async {
      await montarFeed(tester, [_post('p1')]);

      await tocar(
        tester,
        noCard('p1', find.byKey(const ValueKey('detalhe-autor'))),
      );

      expect(find.text('ROTA /perfil bruno'), findsOneWidget);
      expect(find.byType(PublicacaoDetalhePage), findsNothing);
    });

    testWidgets('tocar no local não abre o perfil', (tester) async {
      await montarFeed(tester, [_post('p1')]);

      await tocar(tester, noCard('p1', find.text('Represa de Ibitinga')));

      expect(find.textContaining('ROTA /perfil'), findsNothing);
    });
  });

  group('botões reais do card', () {
    testWidgets('curtir atualiza o card pelo store', (tester) async {
      await montarFeed(tester, [_post('p1')]);

      await tocar(tester, noCard('p1', find.text('Curtir')));

      expect(curtidas.curtidas, ['p1']);
      expect(noCard('p1', find.text('Curtido')), findsOneWidget);
      expect(noCard('p1', find.text('4 curtidas')), findsOneWidget);
    });

    testWidgets('Comentar abre os comentários', (tester) async {
      await montarFeed(tester, [_post('p1')]);

      await tocar(tester, noCard('p1', find.text('Comentar')));

      expect(find.text('Comentários'), findsOneWidget);
      expect(find.byType(PublicacaoDetalhePage), findsNothing);
    });

    testWidgets('Compartilhar manda o texto da publicação', (tester) async {
      await montarFeed(tester, [_post('p1')]);

      await tocar(
        tester,
        noCard('p1', find.widgetWithText(InkWell, 'Compartilhar')),
      );

      expect(compartilhados, hasLength(1));
      expect(compartilhados.single, contains('Bruno Pescador'));
    });

    testWidgets('⋯ de outra pessoa mostra as opções de hoje, sem excluir', (
      tester,
    ) async {
      await montarFeed(tester, [_post('p1')]);

      await tocar(tester, noCard('p1', find.byTooltip('Mais opções')));

      expect(find.text('Copiar link'), findsOneWidget);
      expect(find.text('Denunciar'), findsOneWidget);
      expect(find.text('Excluir publicação'), findsNothing);
    });

    testWidgets('⋯ do próprio post exclui e tira o card da lista', (
      tester,
    ) async {
      await montarFeed(tester, [
        _post('p1', autorId: idEu, autorNome: usuarioEu.nome),
        _post('p2', dia: 2),
      ]);

      await tocar(tester, noCard('p1', find.byTooltip('Mais opções')));
      await tocar(tester, find.text('Excluir publicação'));
      await tocar(tester, find.widgetWithText(TextButton, 'Excluir'));

      expect(card('p1'), findsNothing);
      expect(card('p2'), findsOneWidget);
    });

    testWidgets('a aba Seguindo usa o mesmo card', (tester) async {
      await montarFeed(tester, [_post('s1')]);

      await tocar(tester, find.text('Seguindo'));

      expect(card('s1'), findsOneWidget);
      expect(noCard('s1', find.byType(FotoPublicacao)), findsOneWidget);
      expect(
        noCard('s1', find.byKey(const ValueKey('linha-autor-local'))),
        findsOneWidget,
      );
    });
  });

  testWidgets(
    'rolado até o fim, o último card fica acima do "Ajuda" e responde ao toque',
    (tester) async {
      telaDeCelular(tester);
      await montarFeed(tester, [
        _post('p1', dia: 3),
        _post('p2', dia: 2),
        _post('p3', dia: 1),
      ]);

      // Rola com o dedo até não andar mais.
      final lista = find
          .ancestor(of: card('p1'), matching: find.byType(Scrollable))
          .first;
      final posicao = tester.state<ScrollableState>(lista).position;
      // O p1 sai da árvore ao rolar: o ponto do arrasto é fixado antes.
      final pontoDoArrasto = tester.getCenter(lista);
      for (var i = 0; i < 20 && posicao.pixels < posicao.maxScrollExtent; i++) {
        await tester.dragFrom(pontoDoArrasto, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(posicao.pixels, posicao.maxScrollExtent);

      final ajuda = tester.getRect(find.byType(BotaoAjudaAssistente));
      final ultimoCard = tester.getRect(card('p3'));
      final acoes = tester.getRect(noCard('p3', find.byType(AcoesBar)));
      expect(find.text('Ajuda'), findsOneWidget);
      expect(ultimoCard.bottom, lessThanOrEqualTo(ajuda.top));
      expect(acoes.overlaps(ajuda), isFalse);

      // O Compartilhar fica na mesma coluna do "Ajuda": se o botão cobrisse
      // a barra, o toque abriria o assistente.
      await tester.tap(
        noCard('p3', find.widgetWithText(InkWell, 'Compartilhar')),
      );
      await tester.pumpAndSettle();
      expect(compartilhados, hasLength(1));
      expect(find.textContaining('ROTA /assistente'), findsNothing);

      await tester.tap(noCard('p3', find.text('Curtir')));
      await tester.pumpAndSettle();
      expect(curtidas.curtidas, ['p3']);
    },
  );

  for (final (nome, criarTema, cores) in [
    ('claro', () => AppTheme.light, AppColors.light),
    ('escuro', () => AppTheme.dark, AppColors.dark),
  ]) {
    testWidgets('tema $nome com fonte 1.3 em 360dp: sem estouro', (
      tester,
    ) async {
      telaDeCelular(tester);
      final auth = await authLogado();
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider<AuthProvider>.value(value: auth)],
          child: MaterialApp(
            theme: criarTema(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  PublicacaoCard(
                    key: const ValueKey('p1'),
                    publicacao: _post(
                      'p1',
                      autorNome: 'Bruno Pescador da Silva Santos',
                      localTexto:
                          'Pesqueiro do Seu Zé, estrada velha de Matão, km 12',
                      tags: const ['tucunare', 'represa', 'iscaartificial'],
                      descricao:
                          'Tucunaré de 4kg no fim da tarde, com isca artificial '
                          'e muita paciência na beira da represa.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  PublicacaoCard(
                    key: const ValueKey('p2'),
                    publicacao: _post('p2', imagemUrl: null),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final caixa = tester.widget<Container>(
        find.descendant(of: card('p1'), matching: find.byType(Container)).first,
      );
      final borda = (caixa.decoration! as BoxDecoration).border! as Border;
      expect(borda.top.color, cores.border);
      expect(
        tester
            .widget<Text>(
              noCard('p1', find.textContaining('Pesqueiro do Seu Zé')),
            )
            .style
            ?.color,
        cores.primaryAccent,
      );
      expect(
        tester
            .widget<Text>(noCard('p1', find.textContaining('Tucunaré de 4kg')))
            .style
            ?.color,
        cores.textPrimary,
      );
      expect(
        tester.getSize(noCard('p1', find.byType(FotoPublicacao))).height,
        tester.getSize(noCard('p1', find.byType(FotoPublicacao))).width,
      );
    });
  }
}
