import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/pesquisa/data/pontos_exceptions.dart';
import 'package:pesque_fale_app/features/pesquisa/data/usuarios_busca_repository.dart';
import 'package:pesque_fale_app/features/pesquisa/domain/usuario_resumo.dart';
import 'package:pesque_fale_app/features/pesquisa/providers/pesquisa_usuarios_provider.dart';

class _FakeUsuariosBuscaRepository implements UsuariosBuscaRepository {
  _FakeUsuariosBuscaRepository({this.resultado = const [], this.erro});

  List<UsuarioResumo> resultado;
  PontosException? erro;
  int chamadas = 0;
  String? ultimoTexto;

  @override
  Future<List<UsuarioResumo>> buscar(String texto) async {
    chamadas++;
    ultimoTexto = texto;
    if (erro != null) throw erro!;
    return resultado;
  }
}

const _usuario = UsuarioResumo(id: 'u1', nome: 'Ana', username: 'ana_pesca');

void main() {
  test('idle quando texto vazio, sem chamar a API', () async {
    final repository = _FakeUsuariosBuscaRepository();
    final provider = PesquisaUsuariosProvider(repository: repository);

    provider.alterarBusca('');
    await Future.delayed(const Duration(milliseconds: 500));

    expect(provider.status, PesquisaUsuariosStatus.idle);
    expect(provider.usuarios, isEmpty);
    expect(repository.chamadas, 0);
  });

  test('debounce: so chama a API uma vez apos digitacao rapida', () async {
    final repository = _FakeUsuariosBuscaRepository(resultado: [_usuario]);
    final provider = PesquisaUsuariosProvider(repository: repository);

    provider.alterarBusca('a');
    provider.alterarBusca('an');
    provider.alterarBusca('ana');

    await Future.delayed(const Duration(milliseconds: 600));

    expect(repository.chamadas, 1);
    expect(repository.ultimoTexto, 'ana');
    expect(provider.status, PesquisaUsuariosStatus.sucesso);
    expect(provider.usuarios, [_usuario]);
  });

  test('vazio quando a lista retornada esta vazia', () async {
    final repository = _FakeUsuariosBuscaRepository(resultado: const []);
    final provider = PesquisaUsuariosProvider(repository: repository);

    provider.alterarBusca('zzz');
    await Future.delayed(const Duration(milliseconds: 600));

    expect(provider.status, PesquisaUsuariosStatus.vazio);
  });

  test('erro quando o repositorio lanca excecao', () async {
    final repository = _FakeUsuariosBuscaRepository(
      erro: const InternalServerException(),
    );
    final provider = PesquisaUsuariosProvider(repository: repository);

    provider.alterarBusca('ana');
    await Future.delayed(const Duration(milliseconds: 600));

    expect(provider.status, PesquisaUsuariosStatus.erro);
    expect(provider.mensagemErro, isNotNull);
  });

  test('limpa lista e volta a idle quando texto e apagado', () async {
    final repository = _FakeUsuariosBuscaRepository(resultado: [_usuario]);
    final provider = PesquisaUsuariosProvider(repository: repository);

    provider.alterarBusca('ana');
    await Future.delayed(const Duration(milliseconds: 600));
    expect(provider.status, PesquisaUsuariosStatus.sucesso);

    provider.alterarBusca('');
    expect(provider.status, PesquisaUsuariosStatus.idle);
    expect(provider.usuarios, isEmpty);
  });
}
