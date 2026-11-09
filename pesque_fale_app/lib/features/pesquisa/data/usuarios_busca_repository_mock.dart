import '../domain/usuario_resumo.dart';
import 'usuarios_busca_repository.dart';

class UsuariosBuscaRepositoryMock implements UsuariosBuscaRepository {
  static const _delay = Duration(milliseconds: 400);

  static const _usuarios = [
    UsuarioResumo(
      id: 'u1',
      nome: 'Ana Pescadora',
      username: 'ana_pesca',
      fotoPerfil: 'https://picsum.photos/seed/ana/200/200',
      bio: 'Apaixonada por pesca esportiva e conservação de rios.',
    ),
    UsuarioResumo(
      id: 'u2',
      nome: 'Bruno Sem Foto',
      username: 'bruno_sf',
      bio: 'Só comecei agora, mas já fisguei uma tilápia enorme!',
    ),
    UsuarioResumo(
      id: 'u3',
      nome: 'Carla Rios',
      username: 'carla_rios',
      fotoPerfil: 'https://picsum.photos/seed/carla/200/200',
      bio: 'Pescadora de rio há 10 anos.',
    ),
    UsuarioResumo(
      id: 'u4',
      nome: 'Danilo Pesqueiro',
      username: 'danilo_pesq',
      fotoPerfil: 'https://picsum.photos/seed/danilo/200/200',
      bio: 'Fim de semana é pescaria garantida.',
    ),
    UsuarioResumo(
      id: 'u5',
      nome: 'Elisa Mares',
      username: 'elisa_mares',
      bio: 'Pesca em alto mar e barcos.',
    ),
  ];

  @override
  Future<List<UsuarioResumo>> buscar(String texto) async {
    await Future.delayed(_delay);

    final termo = texto.trim().toLowerCase();
    if (termo.isEmpty) return const [];

    return _usuarios
        .where(
          (u) =>
              u.nome.toLowerCase().contains(termo) ||
              u.username.toLowerCase().contains(termo),
        )
        .toList();
  }
}
