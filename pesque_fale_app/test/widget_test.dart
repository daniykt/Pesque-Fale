import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pesque_fale_app/core/theme/theme_provider.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository_mock.dart';
import 'package:pesque_fale_app/features/auth/data/token_storage.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/main.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App sobe sem erros e usa MaterialApp', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
            ),
          ),
        ],
        child: const PesqueFaleApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App usa pt-BR nos textos padrão do Material', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
            ),
          ),
        ],
        child: const PesqueFaleApp(),
      ),
    );
    await tester.pumpAndSettle();

    final contexto = tester.element(find.byType(Scaffold).first);
    final textos = MaterialLocalizations.of(contexto);
    expect(Localizations.localeOf(contexto), const Locale('pt', 'BR'));
    expect(textos.cancelButtonLabel, 'Cancelar');
    expect(textos.formatMonthYear(DateTime(2026, 11)), 'novembro de 2026');
    expect(
      textos.formatTimeOfDay(
        const TimeOfDay(hour: 15, minute: 30),
        alwaysUse24HourFormat: MediaQuery.of(contexto).alwaysUse24HourFormat,
      ),
      '15:30',
    );
  });
}
