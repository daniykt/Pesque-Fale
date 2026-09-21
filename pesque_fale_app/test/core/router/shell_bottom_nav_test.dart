import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:pesque_fale_app/core/router/shell_bottom_nav.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/notificacoes/data/notificacoes_repository_mock.dart';
import 'package:pesque_fale_app/features/notificacoes/providers/badge_notificacoes_provider.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  /// Monta um app com '/home' na raiz e permite empilhar telas por cima,
  /// cada uma com o [ShellBottomNav] no rodapé.
  Future<void> montarWidget(
    WidgetTester tester, {
    required ValueChanged<int> onSelecionarAba,
    String rotaInicial = '/home',
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<BadgeNotificacoesProvider>(
        create: (_) =>
            BadgeNotificacoesProvider(repository: NotificacoesRepositoryMock()),
        child: MaterialApp(
          theme: AppTheme.light,
          initialRoute: rotaInicial,
          routes: {
            '/home': (_) => const Scaffold(body: Text('tela home')),
            '/empilhada': (_) => Scaffold(
              body: const Text('tela empilhada'),
              bottomNavigationBar: ShellBottomNav(
                onSelecionarAba: onSelecionarAba,
              ),
            ),
            '/outra': (_) => Scaffold(
              body: const Text('tela outra'),
              bottomNavigationBar: ShellBottomNav(
                onSelecionarAba: onSelecionarAba,
              ),
            ),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renderiza os 5 destinos', (tester) async {
    await montarWidget(
      tester,
      onSelecionarAba: (_) {},
      rotaInicial: '/empilhada',
    );

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Pesquisa'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Alertas'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('sem o shell montado a aba selecionada e Inicio', (tester) async {
    await montarWidget(
      tester,
      onSelecionarAba: (_) {},
      rotaInicial: '/empilhada',
    );

    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.selectedIndex, 0);
  });

  testWidgets('tocar em Chat volta ate /home e chama onSelecionarAba(2)', (
    tester,
  ) async {
    final selecionadas = <int>[];
    await montarWidget(tester, onSelecionarAba: selecionadas.add);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/empilhada');
    await tester.pumpAndSettle();
    expect(find.text('tela empilhada'), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('tela empilhada'), findsNothing);
    expect(find.text('tela home'), findsOneWidget);
    expect(selecionadas, [2]);
  });

  testWidgets('com duas telas empilhadas, tocar numa aba desempilha as duas', (
    tester,
  ) async {
    final selecionadas = <int>[];
    await montarWidget(tester, onSelecionarAba: selecionadas.add);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/empilhada');
    await tester.pumpAndSettle();
    navigator.pushNamed('/outra');
    await tester.pumpAndSettle();
    expect(find.text('tela outra'), findsOneWidget);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('tela outra'), findsNothing);
    expect(find.text('tela empilhada'), findsNothing);
    expect(find.text('tela home'), findsOneWidget);
    expect(selecionadas, [4]);
  });

  testWidgets('sem /home na pilha o popUntil para na primeira rota', (
    tester,
  ) async {
    final selecionadas = <int>[];
    await montarWidget(
      tester,
      onSelecionarAba: selecionadas.add,
      rotaInicial: '/empilhada',
    );

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/outra');
    await tester.pumpAndSettle();
    expect(find.text('tela outra'), findsOneWidget);

    await tester.tap(find.text('Pesquisa'));
    await tester.pumpAndSettle();

    // Parou na primeira rota: o navigator nao ficou vazio.
    expect(find.text('tela outra'), findsNothing);
    expect(find.text('tela empilhada'), findsOneWidget);
    expect(selecionadas, [1]);
  });
}
