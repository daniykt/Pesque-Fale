import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/perfil/presentation/widgets/galeria_perfil.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> montar(
    WidgetTester tester, {
    bool isOwnProfile = true,
    List<Publicacao> publicacoes = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: GaleriaPerfil(
              publicacoes: publicacoes,
              isOwnProfile: isOwnProfile,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra o título Publicações como cabeçalho', (tester) async {
    await montar(tester);

    expect(find.text('Publicações'), findsOneWidget);
    final semantica = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.text('Publicações'),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(semantica.properties.header, isTrue);
  });

  testWidgets('não mostra abas nem os placeholders das abas futuras', (
    tester,
  ) async {
    await montar(tester);

    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Equipamentos'), findsNothing);
    expect(find.text('Locais Salvos'), findsNothing);
    expect(find.textContaining('Em breve'), findsNothing);
  });

  testWidgets('no próprio perfil sem publicações oferece Nova Publicação', (
    tester,
  ) async {
    await montar(tester);

    expect(find.text('Nenhuma publicação ainda'), findsOneWidget);
    expect(find.text('Nova Publicação'), findsOneWidget);
  });

  testWidgets('no perfil de outro usuário não oferece Nova Publicação', (
    tester,
  ) async {
    await montar(tester, isOwnProfile: false);

    expect(find.text('Nenhuma publicação ainda'), findsOneWidget);
    expect(find.text('Nova Publicação'), findsNothing);
  });

  testWidgets('em 360dp com fonte 1.3 não estoura o layout', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await montar(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('publicação sem imagem mostra o placeholder', (tester) async {
    await montar(
      tester,
      publicacoes: [
        Publicacao(
          id: 'p1',
          autorId: 'u1',
          autorNome: 'Ana',
          criadoEm: DateTime(2026, 1, 1),
          atualizadoEm: DateTime(2026, 1, 1),
        ),
      ],
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
