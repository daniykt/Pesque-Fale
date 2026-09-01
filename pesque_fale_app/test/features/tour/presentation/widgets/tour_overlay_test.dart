import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/tour/domain/tour_status_storage.dart';
import 'package:pesque_fale_app/features/tour/presentation/widgets/tour_overlay.dart';
import 'package:pesque_fale_app/features/tour/providers/tour_provider.dart';

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

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
  }) async => throw UnimplementedError();

  @override
  Future<AuthResult> login({
    required String email,
    required String senha,
  }) async => throw UnimplementedError();

  @override
  Future<void> logout() async {}
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _FakeFlutterSecureStorageChannel();
  });

  Future<TourProvider> montarWidget(WidgetTester tester) async {
    final tourProvider = TourProvider(
      storage: TourStatusStorage(storage: const FlutterSecureStorage()),
      authProvider: AuthProvider(repository: _FakeAuthRepository()),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<TourProvider>.value(
        value: tourProvider,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: Stack(children: [TourOverlay()])),
        ),
      ),
    );
    await tester.pump();
    return tourProvider;
  }

  testWidgets('nao renderiza nada quando o tour esta inativo', (
    tester,
  ) async {
    await montarWidget(tester);

    expect(find.text('Tour guiado'), findsNothing);
    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgets('renderiza o card com o texto do passo atual quando ativo', (
    tester,
  ) async {
    final tourProvider = await montarWidget(tester);

    tourProvider.iniciarManual();
    await tester.pumpAndSettle();

    expect(find.text('Tour guiado'), findsOneWidget);
    expect(find.text('Bem-vindo!'), findsOneWidget);
    expect(find.text('Passo 1 de 7'), findsOneWidget);
  });

  testWidgets('tocar em Pular encerra o tour e some o overlay', (
    tester,
  ) async {
    final tourProvider = await montarWidget(tester);

    tourProvider.iniciarManual();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();

    expect(find.text('Tour guiado'), findsNothing);
    expect(tourProvider.passoAtualIndex, isNull);
  });

  testWidgets('tocar em Próximo avança o passo exibido no card', (
    tester,
  ) async {
    final tourProvider = await montarWidget(tester);

    tourProvider.iniciarManual();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();

    expect(find.text('Página Inicial'), findsOneWidget);
    expect(find.text('Passo 2 de 7'), findsOneWidget);
  });
}
