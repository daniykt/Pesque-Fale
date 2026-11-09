import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/perfil/presentation/widgets/acoes_proprio_perfil.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const margem = 16.0;
  const espacoEntreBotoes = 12.0;

  final editarFinder = find.widgetWithText(FilledButton, 'Editar perfil');
  final ajustesFinder = find.widgetWithText(OutlinedButton, 'Ajustes');

  Future<void> montar(
    WidgetTester tester, {
    VoidCallback? onEditar,
    VoidCallback? onAjustes,
    ThemeData? tema,
    double largura = 800,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    tester.view.physicalSize = Size(largura, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: tema ?? AppTheme.light,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(size: Size(largura, 1200), textScaler: textScaler),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(margem),
                child: AcoesProprioPerfil(
                  onEditar: onEditar ?? () {},
                  onAjustes: onAjustes ?? () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra Editar perfil e Ajustes, sem Nova Publicação', (
    tester,
  ) async {
    await montar(tester);

    expect(find.text('Editar perfil'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Nova Publicação'), findsNothing);
  });

  testWidgets('cada botão dispara o seu callback uma vez', (tester) async {
    var editar = 0;
    var ajustes = 0;
    await montar(tester, onEditar: () => editar++, onAjustes: () => ajustes++);

    await tester.tap(editarFinder);
    await tester.pump();
    expect(editar, 1);
    expect(ajustes, 0);

    await tester.tap(ajustesFinder);
    await tester.pump();
    expect(editar, 1);
    expect(ajustes, 1);
  });

  testWidgets('os dois botões têm alvo de toque de pelo menos 48dp', (
    tester,
  ) async {
    await montar(tester);

    expect(tester.getSize(editarFinder).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(ajustesFinder).height, greaterThanOrEqualTo(48));
  });

  testWidgets('em tela larga ficam lado a lado, Editar ~2/3 e Ajustes ~1/3', (
    tester,
  ) async {
    const largura = 800.0;
    await montar(tester, largura: largura);

    expect(
      tester.getTopLeft(editarFinder).dy,
      tester.getTopLeft(ajustesFinder).dy,
    );

    final larguraEditar = tester.getSize(editarFinder).width;
    final larguraAjustes = tester.getSize(ajustesFinder).width;
    const larguraUtil = largura - margem * 2;

    expect(larguraEditar, greaterThan(larguraAjustes));
    expect(
      larguraAjustes,
      greaterThanOrEqualTo((larguraUtil - espacoEntreBotoes) / 3),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('com fonte ampliada em tela estreita empilha sem overflow', (
    tester,
  ) async {
    await montar(
      tester,
      largura: 360,
      textScaler: const TextScaler.linear(2.0),
    );

    expect(
      tester.getTopLeft(ajustesFinder).dy,
      greaterThan(tester.getTopLeft(editarFinder).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renderiza no tema escuro sem exceção', (tester) async {
    await montar(tester, tema: AppTheme.dark);

    expect(editarFinder, findsOneWidget);
    expect(ajustesFinder, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
