import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/notificacoes/data/notificacoes_repository.dart';
import 'package:pesque_fale_app/features/notificacoes/domain/notificacao.dart';
import 'package:pesque_fale_app/features/notificacoes/presentation/notificacoes_page.dart';
import 'package:pesque_fale_app/features/notificacoes/presentation/widgets/item_notificacao.dart';
import 'package:pesque_fale_app/features/notificacoes/providers/badge_notificacoes_provider.dart';
import 'package:pesque_fale_app/features/notificacoes/providers/notificacoes_provider.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository_mock.dart';

import '../../chat/support/fake_realtime_manager.dart';

class _FakeNotificacoesRepository implements NotificacoesRepository {
  int naoLidas = 3;
  int chamadasListar = 0;
  int chamadasMarcarLidas = 0;
  final List<String> apagadas = [];
  final Set<String> _removidas = {};

  @override
  Future<int> contarNaoLidas() async => naoLidas;

  @override
  Future<({List<Notificacao> lista, int naoLidas})> listar({
    int pagina = 1,
    int porPagina = 20,
  }) async {
    chamadasListar++;
    final lista = [
      Notificacao(
        id: 'n1',
        para: 'me',
        tipo: TipoNotificacao.sistema,
        texto: 'Bem-vindo',
        lida: naoLidas == 0,
        criadoEm: DateTime(2026, 9, 2),
      ),
      Notificacao(
        id: 'n2',
        para: 'me',
        tipo: TipoNotificacao.sistema,
        texto: 'Complete seu perfil',
        lida: naoLidas == 0,
        criadoEm: DateTime(2026, 9, 1),
      ),
    ].where((n) => !_removidas.contains(n.id)).toList();
    return (lista: lista, naoLidas: naoLidas);
  }

  @override
  Future<void> marcarTodasComoLidas() async {
    chamadasMarcarLidas++;
    naoLidas = 0;
  }

  @override
  Future<void> apagar(String id) async {
    apagadas.add(id);
    _removidas.add(id);
  }

  @override
  Future<void> apagarTodas() async {
    _removidas.addAll(['n1', 'n2']);
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late _FakeNotificacoesRepository repo;
  late FakeRealtimeManager realtime;
  late NotificacoesProvider provider;
  late BadgeNotificacoesProvider badge;

  // Provider e badge sobrevivem entre montagens, como no app (globais).
  setUp(() {
    repo = _FakeNotificacoesRepository();
    realtime = FakeRealtimeManager();
    provider = NotificacoesProvider(
      repository: repo,
      perfilRepository: PerfilRepositoryMock(),
      realtime: realtime,
    );
    badge = BadgeNotificacoesProvider(notificacoes: provider);
  });

  Future<void> montar(WidgetTester tester, {required bool ativa}) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<NotificacoesProvider>.value(value: provider),
          ChangeNotifierProvider<BadgeNotificacoesProvider>.value(value: badge),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: NotificacoesPage(ativa: ativa),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> arrastarPrimeiroItem(WidgetTester tester) async {
    await tester.drag(find.byType(Dismissible).first, const Offset(-600, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('inativa não carrega, não marca como lidas e mantém o badge', (
    tester,
  ) async {
    // Carga do login (reagirAuth), antes de a aba abrir.
    await provider.carregar();

    await montar(tester, ativa: false);

    expect(repo.chamadasListar, 1);
    expect(repo.chamadasMarcarLidas, 0);
    expect(badge.naoLidas, 2);
  });

  testWidgets('ao ficar ativa carrega, marca como lidas e zera o badge', (
    tester,
  ) async {
    await provider.carregar();
    await montar(tester, ativa: false);

    await montar(tester, ativa: true);

    expect(repo.chamadasListar, 2);
    expect(repo.chamadasMarcarLidas, 1);
    expect(badge.naoLidas, 0);
  });

  testWidgets('ao abrir destaca as que estavam não lidas', (tester) async {
    await montar(tester, ativa: true);

    final itens = tester.widgetList<ItemNotificacao>(
      find.byType(ItemNotificacao),
    );
    expect(itens.map((i) => i.destacar), [true, true]);
  });

  testWidgets('notificação em tempo real entra no topo com a aba aberta', (
    tester,
  ) async {
    await montar(tester, ativa: true);

    realtime.emitir('nova_notificacao', {
      'id': 'n-nova',
      'para': 'me',
      'tipo': 'curtida',
      'de': 'Fulano',
      'deUsername': 'fulano',
      'postId': 'pub-1',
      'lida': false,
      'criadoEm': '2026-10-27T12:00:00.000Z',
    });
    await tester.pump();

    final itens = tester.widgetList<ItemNotificacao>(
      find.byType(ItemNotificacao),
    );
    expect(itens.map((i) => i.notif.id), ['n-nova', 'n1', 'n2']);
  });

  testWidgets('recarrega a cada vez que volta a ficar ativa', (tester) async {
    await montar(tester, ativa: true);
    await montar(tester, ativa: false);

    await montar(tester, ativa: true);

    expect(repo.chamadasListar, 2);
  });

  testWidgets('arrastar remove o item e mostra o snackbar com Desfazer', (
    tester,
  ) async {
    await montar(tester, ativa: true);
    expect(find.byType(ItemNotificacao), findsNWidgets(2));

    await arrastarPrimeiroItem(tester);

    expect(find.byType(ItemNotificacao), findsOneWidget);
    expect(find.text('Notificação apagada'), findsOneWidget);
    expect(find.text('Desfazer'), findsOneWidget);
    expect(repo.apagadas, isEmpty);
  });

  testWidgets('Desfazer restaura o item sem chamar a API', (tester) async {
    await montar(tester, ativa: true);
    await arrastarPrimeiroItem(tester);

    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.byType(ItemNotificacao), findsNWidgets(2));
    expect(repo.apagadas, isEmpty);
  });

  testWidgets('sem Desfazer, apaga na API depois de 4 segundos', (
    tester,
  ) async {
    await montar(tester, ativa: true);
    await arrastarPrimeiroItem(tester);

    await tester.pump(const Duration(seconds: 3));
    expect(repo.apagadas, isEmpty);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(repo.apagadas, ['n1']);
    expect(find.byType(ItemNotificacao), findsOneWidget);
  });
}