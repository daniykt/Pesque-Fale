import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/feed/presentation/widgets/skeletons/publicacao_card_skeleton.dart';
import 'package:pesque_fale_app/shared/widgets/imagem_placeholder.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final (nomeTema, criarTema) in [
    ('claro', () => AppTheme.light),
    ('escuro', () => AppTheme.dark),
  ]) {
    testWidgets('área da imagem usa o placeholder de carregamento '
        '(tema $nomeTema)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: criarTema(),
          home: const Scaffold(
            body: SingleChildScrollView(child: PublicacaoCardSkeleton()),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(PublicacaoCardSkeleton),
          matching: find.byType(ImagemCarregando),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
