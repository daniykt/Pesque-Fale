import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository_mock.dart';
import 'package:pesque_fale_app/features/auth/data/token_storage.dart';
import 'package:pesque_fale_app/features/auth/presentation/cadastro/cadastro_page.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final storedValues = <String, String?>{};

  setUp(() {
    storedValues.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'write':
              final args = call.arguments as Map;
              storedValues[args['key'] as String] = args['value'] as String?;
              return null;
            case 'read':
              final args = call.arguments as Map;
              return storedValues[args['key'] as String];
            case 'delete':
              final args = call.arguments as Map;
              storedValues.remove(args['key'] as String);
              return null;
            default:
              return null;
          }
        });
  });

  Widget buildApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            repository: AuthRepositoryMock(tokenStorage: TokenStorage()),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        routes: {
          '/cadastro': (_) => const CadastroPage(),
          '/login': (_) => const Scaffold(),
          '/onboarding': (_) => const Scaffold(),
        },
        initialRoute: '/cadastro',
      ),
    );
  }

  Future<void> preencherCamposValidos(
    WidgetTester tester, {
    String email = 'novo@teste.com',
  }) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome'),
      'Pescador',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
      '123456',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar Senha'),
      '123456',
    );
  }

  Future<void> tapBotao(WidgetTester tester) async {
    await tester.ensureVisible(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(OutlinedButton));
  }

  testWidgets('botao fica desabilitado durante loading', (tester) async {
    await tester.pumpWidget(buildApp());
    await preencherCamposValidos(tester);

    await tapBotao(tester);
    await tester.pump();

    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
  });

  testWidgets('mostra erro de email invalido', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'email-invalido',
    );
    await tapBotao(tester);
    await tester.pump();

    expect(find.text('Informe um email válido.'), findsOneWidget);
  });

  testWidgets('mostra erro inline quando confirmar senha difere', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome'),
      'Pescador',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'novo@teste.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
      '123456',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar Senha'),
      'outraSenha',
    );
    await tapBotao(tester);
    await tester.pump();

    expect(find.text('As senhas não conferem.'), findsOneWidget);
  });

  testWidgets('email ja cadastrado mostra snackbar de erro', (tester) async {
    await tester.pumpWidget(buildApp());
    await preencherCamposValidos(tester, email: 'existente@teste.com');

    await tapBotao(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(); // rebuild Consumer + addPostFrameCallback
    await tester.pump(); // postFrameCallback executa → showSnackBar

    expect(find.text('Este email já está em uso.'), findsOneWidget);
  });
}
