import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:pesque_fale_app/features/onboarding/domain/onboarding_status_storage.dart';
import 'package:pesque_fale_app/features/onboarding/presentation/etapas/onboarding_foto_perfil_page.dart';
import 'package:pesque_fale_app/features/onboarding/presentation/widgets/onboarding_link_pular.dart';
import 'package:pesque_fale_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_repository.dart';
import 'package:pesque_fale_app/features/perfil/domain/perfil_completo.dart';

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
  }) async {
    return const AuthResult(
      accessToken: 'token',
      usuario: Usuario(
        id: '1',
        nome: 'Ana',
        email: 'ana@teste.com',
        onboardingConcluido: false,
      ),
    );
  }

  @override
  Future<void> logout() async {}
}

class _FakePerfilRepository implements PerfilRepository {
  Completer<String>? fotoCompleter;

  @override
  Future<PerfilCompleto> buscarPerfil(
    String id, {
    required String meuId,
  }) async => throw UnimplementedError();

  @override
  Future<void> seguir(String id) async {}

  @override
  Future<void> deixarDeSeguir(String id) async {}

  @override
  Future<String> atualizarFoto(File arquivo) {
    if (fotoCompleter != null) return fotoCompleter!.future;
    return Future.value('https://x.com/foto-nova.png');
  }

  @override
  Future<String> atualizarBanner(File arquivo) async => '';

  @override
  Future<Usuario> editarPerfil(Map<String, dynamic> camposAlterados) async =>
      throw UnimplementedError();

  @override
  Future<bool> verificarUsername(String username) async => true;
}

class _FakeStatusStorage extends OnboardingStatusStorage {
  @override
  Future<bool> isConcluido(String userId) async => false;

  @override
  Future<void> marcarConcluido(String userId) async {}

  @override
  Future<void> limpar(String userId) async {}
}

class _FakeImagePickerChannel {
  _FakeImagePickerChannel() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, _handle);
  }

  static const _channel = MethodChannel('plugins.flutter.io/image_picker');

  String? proximoCaminho;

  Future<dynamic> _handle(MethodCall call) async {
    if (call.method == 'pickImage') return proximoCaminho;
    return null;
  }
}

Future<String> _criarArquivoTemporario({required String extensao}) async {
  final dir = await Directory.systemTemp.createTemp('foto_perfil_test_');
  final arquivo = File('${dir.path}/imagem.$extensao');
  await arquivo.writeAsBytes(List.filled(100, 0));
  return arquivo.path;
}

/// PNG transparente 1x1, usado para responder `Image.network` nos testes
/// sem depender de acesso real à rede.
final _pngUmPorUm = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, //
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, //
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, //
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, //
  0x42, 0x60, 0x82,
]);

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _pngUmPorUm.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_pngUmPorUm]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _FakeHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<
    ({OnboardingProvider provider, _FakePerfilRepository repository})
  >
  montarWidget(WidgetTester tester) async {
    final authProvider = AuthProvider(repository: _FakeAuthRepository());
    await authProvider.login(email: 'ana@teste.com', senha: '123456');

    final repository = _FakePerfilRepository();
    late OnboardingProvider onboardingProvider;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<OnboardingProvider>(
            create: (_) {
              onboardingProvider = OnboardingProvider(
                perfilRepository: repository,
                authProvider: authProvider,
                statusStorage: _FakeStatusStorage(),
              );
              return onboardingProvider;
            },
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingFotoPerfilPage(),
        ),
      ),
    );
    await tester.pump();
    return (provider: onboardingProvider, repository: repository);
  }

  testWidgets('estado vazio mostra icone e texto, botao diz continuar sem foto', (
    tester,
  ) async {
    await montarWidget(tester);

    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
    expect(find.text('Clique para adicionar'), findsOneWidget);
    expect(find.text('Continuar sem foto'), findsOneWidget);
  });

  testWidgets('link pular esta etapa e renderizado', (tester) async {
    await montarWidget(tester);

    expect(find.byType(OnboardingLinkPular), findsOneWidget);
    expect(find.text('Pular esta etapa'), findsOneWidget);
  });

  testWidgets('mostra spinner sobreposto durante o upload', (tester) async {
    debugNetworkImageHttpClientProvider = () => _FakeHttpClient();
    try {
      final imagePickerChannel = _FakeImagePickerChannel();
      final montado = await montarWidget(tester);
      // A criacao do arquivo e o toque disparam I/O real (arquivo em disco e
      // o round-trip do canal do image_picker), que so avanca dentro de
      // runAsync — o pump() comum usa um relogio falso que nunca libera
      // Futures apoiados em I/O real.
      imagePickerChannel.proximoCaminho = await tester.runAsync(
        () => _criarArquivoTemporario(extensao: 'jpg'),
      );
      montado.repository.fotoCompleter = Completer<String>();

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(montado.provider.uploadingFoto, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.runAsync(() async {
        montado.repository.fotoCompleter!.complete('https://x.com/foto.png');
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(montado.provider.uploadingFoto, isFalse);
    } finally {
      debugNetworkImageHttpClientProvider = null;
    }
  });

  testWidgets('mostra a imagem e o badge de lapis apos upload concluido', (
    tester,
  ) async {
    debugNetworkImageHttpClientProvider = () => _FakeHttpClient();
    try {
      final imagePickerChannel = _FakeImagePickerChannel();
      await montarWidget(tester);
      imagePickerChannel.proximoCaminho = await tester.runAsync(
        () => _criarArquivoTemporario(extensao: 'jpg'),
      );

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
      expect(find.text('Continuar sem foto'), findsNothing);
    } finally {
      debugNetworkImageHttpClientProvider = null;
    }
  });
}
