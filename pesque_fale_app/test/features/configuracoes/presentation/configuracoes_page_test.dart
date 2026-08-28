import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pesque_fale_app/core/theme/app_colors.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/core/theme/theme_provider.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository_mock.dart';
import 'package:pesque_fale_app/features/auth/data/token_storage.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/configuracoes/presentation/configuracoes_page.dart';
import 'package:pesque_fale_app/features/configuracoes/providers/preferencias_provider.dart';

/// Fake do canal de plataforma do flutter_secure_storage, backed por um Map
/// em memória, pra que o AuthRepositoryMock.logout() (via TokenStorage) nao
/// dependa de um plugin nativo nos testes.
class _FakeFlutterSecureStorageChannel {
  _FakeFlutterSecureStorageChannel() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, _handle);
  }

  static const _channel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  final Map<String, String> _dados = {};

  Future<dynamic> _handle(MethodCall call) async {
    final args = (call.arguments as Map).cast<String, dynamic>();
    switch (call.method) {
      case 'read':
        return _dados[args['key'] as String];
      case 'write':
        _dados[args['key'] as String] = args['value'] as String;
        return null;
      case 'delete':
        _dados.remove(args['key'] as String);
        return null;
      case 'containsKey':
        return _dados.containsKey(args['key'] as String);
      case 'readAll':
        return _dados;
      case 'deleteAll':
        _dados.clear();
        return null;
    }
    throw UnimplementedError(call.method);
  }
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _FakeFlutterSecureStorageChannel();
  });

  Future<void> montarComProviders(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<PreferenciasProvider>(
            create: (_) => PreferenciasProvider(),
          ),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(
              repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ConfiguracoesPage(),
          routes: {
            '/perfil/editar': (_) =>
                const Scaffold(body: Text('Editar Perfil')),
            '/sobre': (_) => const Scaffold(body: Text('Sobre Nós')),
            '/cadastro': (_) => const Scaffold(body: Text('Cadastro')),
          },
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renderiza AppBar com titulo Configuracoes', (tester) async {
    await montarComProviders(tester);

    expect(find.text('Configurações'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('renderiza as 4 secoes com cabecalhos', (tester) async {
    await montarComProviders(tester);

    expect(find.text('APARÊNCIA'), findsOneWidget);
    expect(find.text('NOTIFICAÇÕES'), findsOneWidget);
    expect(find.text('CONTA'), findsOneWidget);
    expect(find.text('SOBRE'), findsOneWidget);
  });

  testWidgets(
    'renderiza switch Modo escuro refletindo o estado do ThemeProvider',
    (tester) async {
      await montarComProviders(tester);

      expect(find.text('Modo escuro'), findsOneWidget);
      final switchTile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Modo escuro'),
      );
      expect(switchTile.value, isFalse);
    },
  );

  testWidgets('tap no switch Modo escuro chama toggleTheme', (tester) async {
    await montarComProviders(tester);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Modo escuro'));
    await tester.pump();

    final themeProvider = tester
        .element(find.byType(ConfiguracoesPage))
        .read<ThemeProvider>();
    expect(themeProvider.isDarkMode, isTrue);

    final switchTile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Modo escuro'),
    );
    expect(switchTile.value, isTrue);
  });

  testWidgets(
    'renderiza switch Receber notificacoes com valor default true',
    (tester) async {
      await montarComProviders(tester);

      final switchTile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Receber notificações'),
      );
      expect(switchTile.value, isTrue);
    },
  );

  testWidgets('tap no switch Receber notificacoes muda o estado do provider', (
    tester,
  ) async {
    await montarComProviders(tester);

    final preferenciasProvider = tester
        .element(find.byType(ConfiguracoesPage))
        .read<PreferenciasProvider>();

    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Receber notificações'),
    );
    await tester.pump();

    expect(preferenciasProvider.notificacoesAtivas, isFalse);
  });

  testWidgets('renderiza Editar perfil e tap navega para /perfil/editar', (
    tester,
  ) async {
    await montarComProviders(tester);

    expect(find.text('Editar perfil'), findsOneWidget);

    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Editar Perfil'), findsOneWidget);
  });

  testWidgets('renderiza Sair da conta com cor danger', (tester) async {
    await montarComProviders(tester);

    final colors = AppTheme.light.extension<AppColors>()!;
    final tile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Sair da conta'),
    );
    final titleWidget = tile.title as Text;
    expect(titleWidget.style?.color, colors.danger);
  });

  testWidgets('tap em Sair da conta abre AlertDialog com Cancelar e Sair', (
    tester,
  ) async {
    await montarComProviders(tester);

    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Sair'), findsOneWidget);
  });

  testWidgets('cancelar fecha o dialogo sem sair', (tester) async {
    await montarComProviders(tester);

    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(ConfiguracoesPage), findsOneWidget);
  });

  testWidgets(
    'confirmar chama signOut e navega para /cadastro limpando a pilha',
    (tester) async {
      await montarComProviders(tester);

      await tester.tap(find.text('Sair da conta'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Sair'));
      await tester.pumpAndSettle();

      expect(find.text('Cadastro'), findsOneWidget);
      expect(find.byType(ConfiguracoesPage), findsNothing);
    },
  );

  testWidgets('renderiza Sobre o app e tap navega para /sobre', (
    tester,
  ) async {
    await montarComProviders(tester);

    expect(find.text('Sobre o app'), findsOneWidget);

    await tester.tap(find.text('Sobre o app'));
    await tester.pumpAndSettle();

    expect(find.text('Sobre Nós'), findsOneWidget);
  });

  testWidgets(
    'renderiza Versao com texto 1.0.0 no trailing e sem onTap',
    (tester) async {
      await montarComProviders(tester);

      expect(find.text('Versão'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);

      final tile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Versão'),
      );
      expect(tile.onTap, isNull);
    },
  );
}
