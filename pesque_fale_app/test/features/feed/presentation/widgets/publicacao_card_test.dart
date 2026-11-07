import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/presentation/widgets/publicacao_card.dart';
import 'package:pesque_fale_app/shared/widgets/imagem_placeholder.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  final publicacao = Publicacao(
    id: 'p1',
    autorId: 'autor-1',
    autorNome: 'Ana',
    imagemUrl: 'https://res.cloudinary.com/demo/image/upload/quebrada.jpg',
    criadoEm: DateTime(2026, 1, 1),
    atualizadoEm: DateTime(2026, 1, 1),
  );

  for (final (nomeTema, criarTema) in [
    ('claro', () => AppTheme.light),
    ('escuro', () => AppTheme.dark),
  ]) {
    testWidgets('imagem que falha mostra o aviso de indisponível '
        '(tema $nomeTema)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: criarTema(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PublicacaoCard(publicacao: publicacao),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ImagemIndisponivel), findsOneWidget);
      expect(find.text('Imagem indisponível'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mostra a data relativa e não a data e hora completas', (
    tester,
  ) async {
    final recente = Publicacao(
      id: 'p2',
      autorId: 'autor-1',
      autorNome: 'Ana',
      criadoEm: DateTime.now().subtract(const Duration(days: 2)),
      atualizadoEm: DateTime.now().subtract(const Duration(days: 2)),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PublicacaoCard(publicacao: recente),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('há 2 dias'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'\d{2}/\d{2}/\d{4}, \d{2}:\d{2}:\d{2}')),
      findsNothing,
    );
  });
}
