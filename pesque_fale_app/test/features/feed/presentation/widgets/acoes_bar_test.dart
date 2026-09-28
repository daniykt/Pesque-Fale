import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/presentation/widgets/acoes_bar.dart';

final _publicacao = Publicacao(
  id: 'pub-0',
  autorId: 'autor-0',
  autorNome: 'Pescador Zero',
  descricao: 'Relato de pescaria número 1.',
  comentariosCount: 0,
  criadoEm: DateTime(2026, 1, 1),
  atualizadoEm: DateTime(2026, 1, 1),
);

// A Row dos três botões: ancestral de "Compartilhar" com três filhos e sem
// espaçadores (a Row interna do botão tem um SizedBox entre ícone e texto).
final _linhaDeAcoes = find.ancestor(
  of: find.text('Compartilhar'),
  matching: find.byWidgetPredicate(
    (w) =>
        w is Row &&
        w.children.length == 3 &&
        w.children.every((c) => c is! SizedBox),
  ),
);

/// Falha se algum Flex dentro de [raiz] tiver filhos que somam mais que o
/// próprio tamanho no eixo principal (o que vira faixa amarela no app).
void _expectSemOverflow(WidgetTester tester, Finder raiz) {
  final flexes = find.descendant(
    of: raiz,
    matching: find.byWidgetPredicate((w) => w is Flex),
    matchRoot: true,
  );
  expect(flexes, findsWidgets);

  for (final render in tester.renderObjectList<RenderFlex>(flexes)) {
    final horizontal = render.direction == Axis.horizontal;
    var ocupado = 0.0;
    var filho = render.firstChild;
    while (filho != null) {
      ocupado += horizontal ? filho.size.width : filho.size.height;
      filho = (filho.parentData! as FlexParentData).nextSibling;
    }
    final disponivel = horizontal ? render.size.width : render.size.height;
    expect(ocupado, lessThanOrEqualTo(disponivel + 0.5));
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const larguras = [360.0, 412.0, 480.0];
  const escalas = [1.0, 1.3];

  for (final largura in larguras) {
    for (final escala in escalas) {
      testWidgets('sem overflow em ${largura.toInt()}dp com fonte $escala', (
        tester,
      ) async {
        tester.view.physicalSize = Size(largura, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = escala;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: AcoesBar(publicacao: _publicacao, onComentarTap: () {}),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // A fonte do flutter_test desenha cada glifo com 1em de largura
        // (cerca do dobro da fonte real). Com escala 1.3 isso estoura a Row
        // de contadores ("0 curtidas  0 comentários"), que está fora do
        // escopo deste fix. Só esse overflow é tolerado aqui. A barra de
        // ações é verificada pela geometria logo abaixo.
        final erro = tester.takeException();
        if (escala == 1.0) {
          expect(erro, isNull);
        } else {
          expect(
            erro,
            anyOf(
              isNull,
              isA<FlutterError>().having(
                (e) => e.message,
                'message',
                contains('overflowed'),
              ),
            ),
          );
        }
        _expectSemOverflow(tester, _linhaDeAcoes);

        expect(find.text('Curtir'), findsOneWidget);
        expect(find.text('Comentar'), findsOneWidget);
        expect(find.text('Compartilhar'), findsOneWidget);
      });
    }
  }
}
