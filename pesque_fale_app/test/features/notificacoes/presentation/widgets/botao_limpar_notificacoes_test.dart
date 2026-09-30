import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/notificacoes/data/notificacoes_repository.dart';
import 'package:pesque_fale_app/features/notificacoes/domain/notificacao.dart';
import 'package:pesque_fale_app/features/notificacoes/presentation/widgets/botao_limpar_notificacoes.dart';
import 'package:pesque_fale_app/features/notificacoes/providers/badge_notificacoes_provider.dart';
import 'package:pesque_fale_app/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository_mock.dart';

class _FakeNotificacoesRepository implements NotificacoesRepository {
  List<Notificacao> servidor = [
    Notificacao(
      id: 'n1',
      para: 'me',
      tipo: TipoNotificacao.sistema,
      texto: 'Bem-vindo',
      lida: true,
      criadoEm: DateTime(2026, 9, 1),
    ),
  ];
  int chamadasApagarTodas = 0;
  int chamadasContar = 0;
  bool falharApagarTodas = false;

  @override
  Future<({List<Notificacao> lista, int naoLidas})> listar({
    int pagina = 1,
    int porPagina = 20,
  }) async => (lista: servidor, naoLidas: 0);

  @override
  Future<int> contarNaoLidas() async {
    chamadasContar++;
    return 0;
  }

  @override
  Future<void> marcarTodasComoLidas() async {}

  @override
  Future<void> apagar(String id) async {}

  @override
  Future<void> apagarTodas() async {
    chamadasApagarTodas++;
    if (falharApagarTodas) throw Exception('falha');
    servidor = [];
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late _FakeNotificacoesRepository repo;

  setUp(() => repo = _FakeNotificacoesRepository());

  Future<void> montar(WidgetTester tester, {ThemeData? tema}) async {
    final provider = NotificacoesProvider(
      repository: repo,
      perfilRepository: PerfilRepositoryMock(),
    );
    await provider.carregar();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<NotificacoesProvider>.value(value: provider),
          ChangeNotifierProvider<BadgeNotificacoesProvider>(
            create: (_) => BadgeNotificacoesProvider(repository: repo),
          ),
        ],
        child: MaterialApp(
          theme: tema ?? AppTheme.light,
          home: Scaffold(
            appBar: AppBar(actions: const [BotaoLimparNotificacoes()]),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> abrirConfirmacao(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Limpar todas'));
    await tester.pumpAndSettle();
  }

  testWidgets('não aparece quando não há notificações', (tester) async {
    repo.servidor = [];

    await montar(tester);

    expect(find.byTooltip('Limpar todas'), findsNothing);
  });

  testWidgets('aparece quando há notificações', (tester) async {
    await montar(tester);

    expect(find.byTooltip('Limpar todas'), findsOneWidget);
  });

  testWidgets('Cancelar fecha a confirmação sem apagar nada', (tester) async {
    await montar(tester);
    await abrirConfirmacao(tester);

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(repo.chamadasApagarTodas, 0);
    expect(find.byTooltip('Limpar todas'), findsOneWidget);
  });

  testWidgets('confirmar apaga tudo, atualiza o badge e esconde o botão', (
    tester,
  ) async {
    await montar(tester);
    await abrirConfirmacao(tester);

    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();

    expect(repo.chamadasApagarTodas, 1);
    expect(repo.chamadasContar, greaterThan(0));
    expect(find.byTooltip('Limpar todas'), findsNothing);
  });

  testWidgets('falha ao limpar mostra erro e mantém o botão', (tester) async {
    repo.falharApagarTodas = true;
    await montar(tester);
    await abrirConfirmacao(tester);

    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível limpar as notificações.'), findsOneWidget);
    expect(find.byTooltip('Limpar todas'), findsOneWidget);
  });

  testWidgets('no tema escuro, o Cancelar usa a cor de destaque clara', (
    tester,
  ) async {
    await montar(tester, tema: AppTheme.dark);
    await abrirConfirmacao(tester);

    final cor = DefaultTextStyle.of(
      tester.element(find.text('Cancelar')),
    ).style.color;

    expect(cor, AppColors.dark.primaryAccent);
  });
}