import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/perfil/presentation/widgets/cabecalho_perfil.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const bannerPadrao = ValueKey('banner-padrao');

  Future<void> montar(
    WidgetTester tester, {
    required ThemeData Function() tema,
    String? banner,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: tema(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: CabecalhoPerfil(
              usuario: Usuario(
                id: '1',
                nome: 'Ana',
                email: 'ana@teste.com',
                onboardingConcluido: true,
                banner: banner,
              ),
              isOwnProfile: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (nomeTema, tema) in [
    ('claro', () => AppTheme.light),
    ('escuro', () => AppTheme.dark),
  ]) {
    testWidgets(
      'banner inválido ("[BANNER]") cai no gradiente padrão (tema $nomeTema)',
      (tester) async {
        await montar(tester, tema: tema, banner: '[BANNER]');

        expect(tester.takeException(), isNull);
        expect(find.byKey(bannerPadrao), findsOneWidget);
      },
    );

    testWidgets('sem banner mostra o gradiente padrão (tema $nomeTema)', (
      tester,
    ) async {
      await montar(tester, tema: tema);

      expect(tester.takeException(), isNull);
      expect(find.byKey(bannerPadrao), findsOneWidget);
    });
  }
}
