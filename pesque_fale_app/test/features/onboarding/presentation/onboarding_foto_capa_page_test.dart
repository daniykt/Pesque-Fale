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
import 'package:pesque_fale_app/features/onboarding/domain/onboarding_etapa.dart';
import 'package:pesque_fale_app/features/onboarding/domain/onboarding_status_storage.dart';
import 'package:pesque_fale_app/features/onboarding/presentation/etapas/onboarding_foto_capa_page.dart';
import 'package:pesque_fale_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:pesque_fale_app/features/perfil/data/perfil_exceptions.dart';
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
        id: 'user-1',
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
  _FakePerfilRepository({this.falharAoEditar = false});

  final bool falharAoEditar;
  Completer<String>? capaCompleter;
  Map<String, dynamic>? ultimosCampos;

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
  Future<String> atualizarFoto(File arquivo) async => '';

  @override
  Future<String> atualizarBanner(File arquivo) {
    if (capaCompleter != null) return capaCompleter!.future;
    return Future.value('https://x.com/capa-nova.png');
  }

  @override
  Future<Usuario> editarPerfil(Map<String, dynamic> camposAlterados) async {
    ultimosCampos = camposAlterados;
    if (falharAoEditar) {
      throw PerfilValidationException({'nome': 'Nome inválido.'});
    }
    return Usuario(
      id: 'user-1',
      nome: camposAlterados['nome'] as String? ?? 'Ana',
      email: 'ana@teste.com',
      username: camposAlterados['username'] as String?,
      onboardingConcluido: true,
    );
  }

  @override
  Future<bool> verificarUsername(String username) async => true;
}

class _FakeStatusStorage extends OnboardingStatusStorage {
  final Map<String, bool> _dados = {};

  @override
  Future<bool> isConcluido(String userId) async => _dados[userId] ?? false;

  @override
  Future<void> marcarConcluido(String userId) async {
    _dados[userId] = true;
  }

  @override
  Future<void> limpar(String userId) async {
    _dados.remove(userId);
  }
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
  final dir = await Directory.systemTemp.createTemp('foto_capa_test_');
  final arquivo = File('${dir.path}/imagem.$extensao');
  await arquivo.writeAsBytes(List.filled(100, 0));
  return arquivo.path;
}

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
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<
    ({
      OnboardingProvider provider,
      _FakePerfilRepository repository,
      _FakeStatusStorage statusStorage,
    })
  >
  montarWidget(WidgetTester tester, {bool falharAoEditar = false}) async {
    final authProvider = AuthProvider(repository: _FakeAuthRepository());
    await authProvider.login(email: 'ana@teste.com', senha: '123456');

    final repository = _FakePerfilRepository(falharAoEditar: falharAoEditar);
    final statusStorage = _FakeStatusStorage();
    late OnboardingProvider onboardingProvider;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<OnboardingProvider>(
            create: (_) {
              onboardingProvider = OnboardingProvider(
                perfilRepository: repository,
                authProvider: authProvider,
                statusStorage: statusStorage,
              );
              onboardingProvider.username = 'ana_pesca';
              return onboardingProvider;
            },
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingFotoCapaPage(),
        ),
      ),
    );
    await tester.pump();
    return (
      provider: onboardingProvider,
      repository: repository,
      statusStorage: statusStorage,
    );
  }

  testWidgets('estado vazio mostra retangulo tracejado e continuar sem capa', (
    tester,
  ) async {
    await montarWidget(tester);

    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    expect(find.text('Clique para adicionar uma capa'), findsOneWidget);
    expect(find.text('Continuar sem capa'), findsOneWidget);
  });

  testWidgets('mostra spinner sobreposto durante o upload da capa', (
    tester,
  ) async {
    debugNetworkImageHttpClientProvider = () => _FakeHttpClient();
    try {
      final imagePickerChannel = _FakeImagePickerChannel();
      final montado = await montarWidget(tester);
      imagePickerChannel.proximoCaminho = await tester.runAsync(
        () => _criarArquivoTemporario(extensao: 'jpg'),
      );
      montado.repository.capaCompleter = Completer<String>();

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(montado.provider.uploadingCapa, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.runAsync(() async {
        montado.repository.capaCompleter!.complete('https://x.com/capa.png');
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
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
        await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
      expect(find.text('Continuar sem capa'), findsNothing);
    } finally {
      debugNetworkImageHttpClientProvider = null;
    }
  });

  testWidgets(
    'tap em continuar sem capa chama concluir e avanca para a etapa de sucesso',
    (tester) async {
      final montado = await montarWidget(tester);

      await tester.tap(find.text('Continuar sem capa'));
      await tester.pump();
      await tester.pump();

      expect(montado.provider.etapaAtual, OnboardingEtapa.sucesso);
      expect(await montado.statusStorage.isConcluido('user-1'), isTrue);
    },
  );

  testWidgets(
    'tap em continuar sem capa exibe erro quando concluir falha',
    (tester) async {
      final montado = await montarWidget(tester, falharAoEditar: true);

      await tester.tap(find.text('Continuar sem capa'));
      await tester.pump();
      await tester.pump();

      expect(montado.provider.etapaAtual, isNot(OnboardingEtapa.sucesso));
      expect(find.byType(SnackBar), findsOneWidget);
    },
  );
}
