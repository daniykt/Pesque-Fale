import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/core/theme/theme_provider.dart';
import 'package:pesque_fale_app/features/onboarding/presentation/widgets/onboarding_fab_tema.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ThemeProvider> montarWidget(WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>.value(
        value: themeProvider,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: OnboardingFabTema()),
        ),
      ),
    );
    await tester.pump();
    return themeProvider;
  }

  testWidgets('icone e dark_mode_outlined quando tema e light', (
    tester,
  ) async {
    await montarWidget(tester);

    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(find.byIcon(Icons.light_mode_outlined), findsNothing);
  });

  testWidgets('icone e light_mode_outlined quando tema e dark', (
    tester,
  ) async {
    final themeProvider = await montarWidget(tester);
    await themeProvider.setThemeMode(ThemeMode.dark);
    await tester.pump();

    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsNothing);
  });

  testWidgets('tap chama toggleTheme no provider', (tester) async {
    final themeProvider = await montarWidget(tester);
    expect(themeProvider.isDarkMode, isFalse);

    await tester.tap(find.byType(OnboardingFabTema));
    await tester.pump();

    expect(themeProvider.isDarkMode, isTrue);
  });
}
