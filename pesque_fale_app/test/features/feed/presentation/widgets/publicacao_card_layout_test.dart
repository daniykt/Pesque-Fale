import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/utils/cloudinary_url.dart';
import 'package:pesque_fale_app/features/feed/domain/publicacao.dart';
import 'package:pesque_fale_app/features/feed/presentation/widgets/acoes_bar.dart';
import 'package:pesque_fale_app/features/feed/presentation/widgets/publicacao_card.dart';
import 'package:pesque_fale_app/features/visualizacao_post/presentation/widgets/foto_publicacao.dart';
import 'package:pesque_fale_app/features/visualizacao_post/presentation/widgets/linha_autor_publicacao.dart';
import 'package:pesque_fale_app/shared/widgets/estrelas_readonly.dart';
import 'package:pesque_fale_app/shared/widgets/imagem_placeholder.dart';

/// Tema sem GoogleFonts: o runAsync que cria as imagens deixaria o
/// carregamento das fontes rodar e falhar (o mesmo motivo do
/// foto_publicacao_test). O tema real, claro e escuro, é coberto no
/// feed_card_acoes_test.
final _tema = ThemeData(extensions: const [AppColors.light]);

Publicacao _publicacao({
  String id = 'p1',
  String? descricao = 'Tucunaré de 4kg no fim da tarde.',
  String? imagemUrl,
  String? localTexto = 'Represa de Ibitinga',
  List<String> tags = const ['tucunare', 'represa'],
}) => Publicacao(
  id: id,
  autorId: 'bruno',
  autorNome: 'Bruno Pescador',
  autorUsername: 'bruno',
  descricao: descricao,
  imagemUrl: imagemUrl,
  localTexto: localTexto,
  avaliacaoNota: 4.5,
  pontoId: 'ponto-1',
  tags: tags,
  curtidasCount: 3,
  comentariosCount: 2,
  criadoEm: DateTime(2026, 1, 1),
  atualizadoEm: DateTime(2026, 1, 1),
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  void telaDeCelular(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// O card numa lista com a margem do feed (12).
  Future<void> montar(WidgetTester tester, Publicacao publicacao) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _tema,
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [PublicacaoCard(publicacao: publicacao)],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Põe no cache de imagens, na URL que a FotoPublicacao pede, uma foto de
  /// [largura] × [altura]: a imagem de rede não carrega em widget test.
  Future<ui.Image> fotoNoCache(
    WidgetTester tester,
    String url,
    int largura,
    int altura,
  ) async {
    final imagem = await tester.runAsync(() async {
      final gravador = ui.PictureRecorder();
      Canvas(gravador).drawRect(
        Rect.fromLTWH(0, 0, largura.toDouble(), altura.toDouble()),
        Paint()..color = const Color(0xFF2E7D32),
      );
      return gravador.endRecording().toImage(largura, altura);
    });
    final chave = NetworkImage(
      CloudinaryUrl.otimizar(url, largura: 1080, altura: 1080),
    );
    PaintingBinding.instance.imageCache.putIfAbsent(
      chave,
      () => OneFrameImageStreamCompleter(
        SynchronousFuture(ImageInfo(image: imagem!.clone())),
      ),
    );
    return imagem!;
  }

  double topo(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy;

  Finder linhaDoLocal() => find.byKey(const ValueKey('linha-autor-local'));

  group('ordem e linha do autor', () {
    testWidgets('autor, local, texto, tags, foto e ações, de cima para baixo', (
      tester,
    ) async {
      await montar(
        tester,
        _publicacao(
          imagemUrl: 'https://res.cloudinary.com/demo/image/upload/v1/a.jpg',
        ),
      );

      final blocos = [
        find.byKey(const ValueKey('detalhe-autor')),
        linhaDoLocal(),
        find.text('Tucunaré de 4kg no fim da tarde.'),
        find.text('#tucunare'),
        find.byType(FotoPublicacao),
        find.text('3 curtidas'),
        find.text('Curtir'),
      ];
      for (final bloco in blocos) {
        expect(bloco, findsOneWidget);
      }
      for (var i = 1; i < blocos.length; i++) {
        expect(
          topo(tester, blocos[i]),
          greaterThan(topo(tester, blocos[i - 1])),
          reason: 'o bloco $i deveria vir depois do bloco ${i - 1}',
        );
      }
    });

    testWidgets('⋯ fica na linha do autor, à direita do nome', (tester) async {
      await montar(tester, _publicacao());

      final menu = find.byTooltip('Mais opções');
      expect(menu, findsOneWidget);
      expect(
        find.descendant(of: find.byType(LinhaAutorPublicacao), matching: menu),
        findsOneWidget,
      );
      final autor = tester.getRect(find.byKey(const ValueKey('detalhe-autor')));
      final rectMenu = tester.getRect(menu);
      expect(rectMenu.center.dy, closeTo(autor.center.dy, 1));
      expect(rectMenu.left, greaterThanOrEqualTo(autor.right));
      expect(rectMenu.top, lessThan(topo(tester, linhaDoLocal())));
      // "@username · tempo relativo" na linha do autor.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('detalhe-autor')),
          matching: find.text('@bruno · 01/01/2026'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('local numa linha própria, com pin, fora do toque do perfil', (
      tester,
    ) async {
      await montar(tester, _publicacao());

      expect(
        find.descendant(
          of: linhaDoLocal(),
          matching: find.byIcon(Icons.location_on),
        ),
        findsOneWidget,
      );
      final texto = tester.widget<Text>(
        find.descendant(
          of: linhaDoLocal(),
          matching: find.text('Represa de Ibitinga'),
        ),
      );
      expect(texto.style?.color, AppColors.light.primaryAccent);
      expect(texto.maxLines, 1);
      expect(texto.overflow, TextOverflow.ellipsis);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('detalhe-autor')),
          matching: find.text('Represa de Ibitinga'),
        ),
        findsNothing,
      );
      // Alinhado ao nome, não ao avatar.
      expect(
        tester.getTopLeft(find.byIcon(Icons.location_on)).dx,
        closeTo(tester.getTopLeft(find.text('Bruno Pescador')).dx, 1),
      );
    });

    testWidgets('sem local, sem a linha do local', (tester) async {
      await montar(tester, _publicacao(localTexto: null));

      expect(linhaDoLocal(), findsNothing);
      expect(find.byIcon(Icons.location_on), findsNothing);
    });

    testWidgets('local em branco também não mostra a linha', (tester) async {
      await montar(tester, _publicacao(localTexto: '  '));

      expect(linhaDoLocal(), findsNothing);
    });

    testWidgets('local longo é cortado com reticências em 360dp', (
      tester,
    ) async {
      telaDeCelular(tester);
      await montar(
        tester,
        _publicacao(
          localTexto:
              'Pesqueiro do Seu Zé, estrada velha de Matão a Araraquara, km 12',
        ),
      );

      final paragrafo = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: linhaDoLocal(),
          matching: find.textContaining('Pesqueiro do Seu Zé'),
        ),
      );
      expect(paragrafo.didExceedMaxLines, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sem o card de local com estrelas: ele fica no detalhe', (
      tester,
    ) async {
      await montar(tester, _publicacao());

      expect(find.byType(EstrelasReadonly), findsNothing);
      expect(find.textContaining('nota do pescador'), findsNothing);
      expect(find.byKey(const ValueKey('detalhe-card-local')), findsNothing);
    });
  });

  group('foto em quadro 1:1', () {
    for (final (nome, largura, altura) in [
      ('em pé', 40, 80),
      ('deitada', 80, 40),
      ('quadrada', 50, 50),
    ]) {
      testWidgets('foto $nome ocupa a largura do card num quadrado', (
        tester,
      ) async {
        telaDeCelular(tester);
        final url = 'https://res.cloudinary.com/demo/image/upload/v1/$nome.jpg';
        final imagem = await fotoNoCache(tester, url, largura, altura);
        await montar(tester, _publicacao(imagemUrl: url));

        expect(find.byType(ImagemIndisponivel), findsNothing);
        expect(find.byType(ImagemCarregando), findsNothing);
        // A foto mostrada é a do cache, com as proporções dela.
        final raw = tester.widget<RawImage>(
          find.descendant(
            of: find.byType(FotoPublicacao),
            matching: find.byType(RawImage),
          ),
        );
        expect(raw.image!.width, imagem.width);
        expect(raw.image!.height, imagem.height);
        expect(raw.fit, BoxFit.cover);

        // 360 − 2 × 12 de margem da lista − 2 × 1 de borda do card.
        expect(
          tester.getSize(find.byType(FotoPublicacao)),
          const Size(334, 334),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('com foto, o texto fica em 16px', (tester) async {
      await montar(
        tester,
        _publicacao(
          imagemUrl: 'https://res.cloudinary.com/demo/image/upload/v1/b.jpg',
        ),
      );

      final texto = tester.widget<Text>(
        find.text('Tucunaré de 4kg no fim da tarde.'),
      );
      expect(texto.style?.fontSize, 16);
    });

    testWidgets('sem foto: nenhum bloco de imagem e texto em 18px', (
      tester,
    ) async {
      await montar(tester, _publicacao(imagemUrl: null));

      expect(find.byType(FotoPublicacao), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(find.byType(AspectRatio), findsNothing);
      expect(find.byType(ImagemIndisponivel), findsNothing);
      final texto = tester.widget<Text>(
        find.text('Tucunaré de 4kg no fim da tarde.'),
      );
      expect(texto.style?.fontSize, 18);
      // As ações vêm logo depois das tags.
      expect(
        topo(tester, find.byType(AcoesBar)),
        greaterThan(topo(tester, find.text('#tucunare'))),
      );
    });

    testWidgets('URL em branco conta como sem foto', (tester) async {
      await montar(tester, _publicacao(imagemUrl: '  '));

      expect(find.byType(FotoPublicacao), findsNothing);
    });
  });

  testWidgets('a caixa do card continua com borda e raio de hoje', (
    tester,
  ) async {
    await montar(tester, _publicacao());

    final caixa = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(PublicacaoCard),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoracao = caixa.decoration! as BoxDecoration;
    expect((decoracao.border! as Border).top.color, AppColors.light.border);
    expect(decoracao.borderRadius, BorderRadius.circular(12));
    expect(caixa.clipBehavior, Clip.antiAlias);
  });
}
