import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pesque_fale_app/core/theme/app_theme.dart';
import 'package:pesque_fale_app/core/theme/theme_provider.dart';
import 'package:pesque_fale_app/features/auth/data/auth_repository.dart';
import 'package:pesque_fale_app/features/auth/domain/auth_result.dart';
import 'package:pesque_fale_app/features/auth/domain/usuario.dart';
import 'package:pesque_fale_app/features/auth/providers/auth_provider.dart';
import 'package:pesque_fale_app/features/onboarding/presentation/etapas/onboarding_sucesso_page.dart';
import 'package:pesque_fale_app/features/tour/domain/tour_status_storage.dart';
import 'package:pesque_fale_app/features/tour/providers/tour_provider.dart';

/// Fake do canal de plataforma do flutter_secure_storage, com os dados
/// mantidos em um Map em memória (sem depender de nenhum plugin nativo).
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _FakeFlutterSecureStorageChannel();
  });

  Future<TourProvider> montarWidget(WidgetTester tester) async {
    final authProvider = AuthProvider(repository: _FakeAuthRepository())
      ..atualizarUsuario(
        const Usuario(
          id: 'user-1',
          nome: 'Ana',
          email: 'ana@teste.com',
          onboardingConcluido: true,
        ),
      );
    final tourProvider = TourProvider(
      storage: TourStatusStorage(storage: const FlutterSecureStorage()),
      authProvider: authProvider,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<TourProvider>.value(value: tourProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingSucessoPage(),
          routes: {
            '/home': (_) => const Scaffold(body: Text('Home')),
          },
        ),
      ),
    );
    await tester.pump();
    return tourProvider;
  }

  testWidgets('renderiza titulo e subtitulo', (tester) async {
    await montarWidget(tester);

    expect(find.text('Perfil completo, bora pescar!'), findsOneWidget);
    expect(
      find.textContaining('Seu perfil foi configurado com sucesso'),
      findsOneWidget,
    );
  });

  testWidgets('renderiza o emoji de festa', (tester) async {
    await montarWidget(tester);

    expect(find.text('🎉'), findsOneWidget);
  });

  testWidgets('tap em Ir para Home navega para /home removendo a pilha', (
    tester,
  ) async {
    await montarWidget(tester);

    await tester.tap(find.text('Ir para Home'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingSucessoPage), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('tap em Ir para Home dispara o tour guiado pendente', (
    tester,
  ) async {
    final tourProvider = await montarWidget(tester);

    await tester.tap(find.text('Ir para Home'));
    await tester.pumpAndSettle();

    expect(tourProvider.passoAtualIndex, 0);
  });
}
