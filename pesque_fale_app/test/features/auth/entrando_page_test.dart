import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/presentation/entrando/entrando_page.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  final aviso = find.text('Quase lá…');
  final home = find.text('HOME');

  Future<void> montar(
    WidgetTester tester, {
    required Future<void> Function() preparar,
    Duration limite = const Duration(seconds: 10),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: EntrandoPage(preparar: preparar, limite: limite),
        routes: {'/home': (_) => const Scaffold(body: Text('HOME'))},
      ),
    );
  }

  testWidgets('começa com o logo, sem indicador de carregamento', (
    tester,
  ) async {
    await montar(tester, preparar: () async {});

    expect(find.byType(Image), findsNWidgets(2));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(aviso, findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('com rede rápida, segura a tela por no mínimo 800ms', (
    tester,
  ) async {
    await montar(tester, preparar: () async {});

    await tester.pump(const Duration(milliseconds: 700));
    expect(home, findsNothing);
    expect(find.byType(EntrandoPage), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(home, findsOneWidget);
    expect(find.byType(EntrandoPage), findsNothing);
  });

  testWidgets(
    'com rede lenta, mostra Quase lá… depois de 2,5s e entra ao terminar',
    (tester) async {
      final carregamento = Completer<void>();
      await montar(tester, preparar: () => carregamento.future);

      await tester.pump(const Duration(milliseconds: 2400));
      expect(aviso, findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));
      expect(aviso, findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(home, findsNothing);

      carregamento.complete();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(home, findsOneWidget);
    },
  );

  testWidgets('se o carregamento falhar, entra mesmo assim', (tester) async {
    await montar(tester, preparar: () async => throw Exception('sem rede'));

    await tester.pump(const Duration(milliseconds: 850));
    await tester.pumpAndSettle();

    expect(home, findsOneWidget);
  });

  testWidgets('se o carregamento travar, entra ao atingir o limite', (
    tester,
  ) async {
    await montar(
      tester,
      preparar: () => Completer<void>().future,
      limite: const Duration(seconds: 5),
    );

    await tester.pump(const Duration(seconds: 4));
    expect(home, findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(home, findsOneWidget);
  });

  testWidgets('bloqueia o botão voltar durante a transição', (tester) async {
    await montar(tester, preparar: () async {});

    final popScope = tester.widget<PopScope>(find.byType(PopScope));
    expect(popScope.canPop, isFalse);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });
}