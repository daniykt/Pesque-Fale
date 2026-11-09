import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/shared/widgets/badge_equipe/badge_equipe.dart';
import 'package:pesque_fale_app/shared/widgets/badge_equipe/badge_nome_usuario.dart';
import 'package:pesque_fale_app/shared/widgets/badge_equipe/tipo_badge.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montar(
    WidgetTester tester, {
    required String? userId,
    String nome = 'Fulano',
    double largura = 400,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: largura,
              child: BadgeNomeUsuario(
                userId: userId,
                nome: Text(nome, key: const Key('nome')),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('usuario comum mostra so o nome', (tester) async {
    await montar(tester, userId: '00000000-0000-0000-0000-000000000000');

    expect(find.byKey(const Key('nome')), findsOneWidget);
    expect(find.byType(BadgeEquipe), findsNothing);
    expect(find.byType(Wrap), findsNothing);
  });

  testWidgets('userId null mostra so o nome', (tester) async {
    await montar(tester, userId: null);

    expect(find.byKey(const Key('nome')), findsOneWidget);
    expect(find.byType(BadgeEquipe), findsNothing);
  });

  testWidgets('dev mostra nome + badge DEV', (tester) async {
    await montar(tester, userId: idsDevs.first);

    expect(find.byKey(const Key('nome')), findsOneWidget);
    expect(find.byType(BadgeEquipe), findsOneWidget);
    expect(find.text('DEV'), findsOneWidget);
  });

  testWidgets('oficial mostra nome + badge OFICIAL', (tester) async {
    await montar(tester, userId: idsOficial.first);

    expect(find.byKey(const Key('nome')), findsOneWidget);
    expect(find.text('OFICIAL'), findsOneWidget);
  });

  testWidgets('nome curto deixa o badge na mesma linha', (tester) async {
    await montar(tester, userId: idsDevs.first);

    final nome = tester.getRect(find.byKey(const Key('nome')));
    final badge = tester.getRect(find.byType(BadgeEquipe));
    expect(badge.left, greaterThan(nome.right));
    expect(badge.center.dy, closeTo(nome.center.dy, 2));
  });

  testWidgets('em 400px um nome longo empurra o badge pra linha de baixo '
      'sem overflow', (tester) async {
    await montar(
      tester,
      userId: idsDevs.first,
      nome: 'Danilo de Souza Pereira Albuquerque Nascimento Filho',
    );

    expect(tester.takeException(), isNull);

    final nome = tester.getRect(find.byKey(const Key('nome')));
    final badge = tester.getRect(find.byType(BadgeEquipe));
    expect(badge.top, greaterThanOrEqualTo(nome.bottom));
    expect(badge.right, lessThanOrEqualTo(400));
  });
}
