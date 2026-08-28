import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/core/theme/theme_provider.dart';
import 'package:pesque_fale_app/features/onboarding/presentation/etapas/onboarding_sucesso_page.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> montarWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingSucessoPage(),
          routes: {
            '/home': (_) => const Scaffold(body: Text('Home')),
          },
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renderiza titulo e subtitulo', (tester) async {
    await montarWidget(tester);

    expect(find.text('Perfil completo, bora pescar!'), findsOneWidget);
    expect(
      find.textContaining('Seu perfil foi configurado com sucesso'),
      findsOneWidget,
    );
  });

  testWidgets('renderiza o emoji de festa', (tester) async {
    await montarWidget(tester);

    expect(find.text('🎉'), findsOneWidget);
  });

  testWidgets('tap em Ir para Home navega para /home removendo a pilha', (
    tester,
  ) async {
    await montarWidget(tester);

    await tester.tap(find.text('Ir para Home'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingSucessoPage), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });
}
