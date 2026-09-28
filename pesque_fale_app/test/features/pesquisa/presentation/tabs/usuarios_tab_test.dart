import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/pesquisa/data/usuarios_busca_repository.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/usuario_resumo.dart';
import 'package:pesque_fale_app/features/pesquisa/presentation/tabs/usuarios_tab.dart';
import 'package:pesque_fale_app/features/pesquisa/providers/pesquisa_usuarios_provider.dart';

class _FakeUsuariosBuscaRepository implements UsuariosBuscaRepository {
  @override
  Future<List<UsuarioResumo>> buscar(String texto) async => const [];
}

// Mesma altura do chrome da PesquisaPage (AppBar + TabBar Usuarios/Locais),
// para o espaco do body no teste bater com o do app.
const _appBarPesquisa = PreferredSize(
  preferredSize: Size.fromHeight(kToolbarHeight + kTextTabBarHeight),
  child: SizedBox.expand(),
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('estado idle sem overflow em 360x640 com teclado e fonte 1.3', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final provider = PesquisaUsuariosProvider(
      repository: _FakeUsuariosBuscaRepository(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(appBar: _appBarPesquisa, body: UsuariosTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('Digite o nome de um pescador para começar'),
      findsOneWidget,
    );
  });
}
