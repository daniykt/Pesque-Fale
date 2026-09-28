import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_repository.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/filtros_locais.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/ponto.dart';
import 'package:pesque_fale_app/features/pesquisa/presentation/tabs/locais_tab.dart';
import 'package:pesque_fale_app/features/pesquisa/providers/pesquisa_locais_provider.dart';

class _FakePontosRepository implements PontosRepository {
  @override
  Future<List<Ponto>> buscar({
    required FiltrosLocais filtros,
    double? lat,
    double? lng,
    bool incluirDistancia = false,
    String? ordem,
  }) async => const [];

  @override
  Future<Ponto> buscarPorId(String id) async => throw UnimplementedError();
}

// Mesma altura do chrome da PesquisaPage (AppBar + TabBar Usuarios/Locais),
// para o espaco do body no teste bater com o do app.
const _appBarPesquisa = PreferredSize(
  preferredSize: Size.fromHeight(kToolbarHeight + kTextTabBarHeight),
  child: SizedBox.expand(),
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const tamanhos = [Size(360, 640), Size(412, 915)];
  const alturaTeclado = 300.0;

  for (final tamanho in tamanhos) {
    testWidgets('estado vazio sem overflow em ${tamanho.width.toInt()}x'
        '${tamanho.height.toInt()} com teclado e fonte 1.3', (tester) async {
      tester.view.physicalSize = tamanho;
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: alturaTeclado);
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final provider = PesquisaLocaisProvider(
        repository: _FakePontosRepository(),
      );
      await provider.recarregar();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(appBar: _appBarPesquisa, body: LocaisTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Nenhum local encontrado com esses filtros'),
        findsOneWidget,
      );
    });
  }
}
