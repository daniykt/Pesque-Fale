import 'package:flutter/foundation.dart';

import '../../auth/providers/auth_provider.dart';
import '../domain/tour_passo.dart';
import '../domain/tour_status_storage.dart';

/// Controla o tour guiado global (7 passos), disparado automaticamente após
/// o onboarding ou manualmente via AppDrawer/Configurações.
class TourProvider extends ChangeNotifier {
  TourProvider({required this.storage, required this.authProvider});

  final TourStatusStorage storage;
  final AuthProvider authProvider;

  static const List<TourPasso> roteiro = [
    TourPasso(
      index: 0,
      titulo: 'Bem-vindo!',
      descricao:
          'Vamos fazer um tour rápido pelo Pesque & Fale para você conhecer '
          'as principais funcionalidades do app.',
      abaAlvo: 0,
    ),
    TourPasso(
      index: 1,
      titulo: 'Página Inicial',
      descricao:
          'Acompanhe as publicações, eventos e dicas do dia. É o coração '
          'da plataforma!',
      abaAlvo: 0,
    ),
    TourPasso(
      index: 2,
      titulo: 'Pesquisa',
      descricao:
          'Pesquise pontos de pesca, filtre por tipo e abra o mapa dos '
          'pontos próximos de você.',
      abaAlvo: 1,
    ),
    TourPasso(
      index: 3,
      titulo: 'Chat',
      descricao:
          'Converse com outros pescadores, troque dicas e combine '
          'pescarias.',
      abaAlvo: 2,
    ),
    TourPasso(
      index: 4,
      titulo: 'Notificações',
      descricao:
          'Fique por dentro de curtidas e comentários nas suas publicações.',
      abaAlvo: 3,
    ),
    TourPasso(
      index: 5,
      titulo: 'Seu Perfil',
      descricao:
          'Personalize sua conta, veja suas publicações e gerencie suas '
          'informações.',
      abaAlvo: 4,
    ),
    TourPasso(
      index: 6,
      titulo: 'Menu de Opções',
      descricao:
          'Aqui você acessa as Configurações do app, com Modo Escuro, '
          'notificações e a opção de sair da conta.',
      abaAlvo: 4,
    ),
  ];

  int? _passoAtualIndex;
  String? _userIdAtivo;

  int? get passoAtualIndex => _passoAtualIndex;

  TourPasso? get passoAtual =>
      _passoAtualIndex == null ? null : roteiro[_passoAtualIndex!];

  Future<void> iniciarSePendente(String userId) async {
    if (await storage.jaViu(userId)) return;
    _userIdAtivo = userId;
    _passoAtualIndex = 0;
    notifyListeners();
  }

  void iniciarManual() {
    _userIdAtivo = authProvider.usuario?.id;
    _passoAtualIndex = 0;
    notifyListeners();
  }

  void avancar() {
    if (_passoAtualIndex == null) return;
    if (_passoAtualIndex! >= roteiro.length - 1) {
      concluir();
      return;
    }
    _passoAtualIndex = _passoAtualIndex! + 1;
    notifyListeners();
  }

  void voltar() {
    if (_passoAtualIndex == null || _passoAtualIndex == 0) return;
    _passoAtualIndex = _passoAtualIndex! - 1;
    notifyListeners();
  }

  Future<void> pular() async {
    await _marcarComoVistoSeHouverUsuario();
    _encerrar();
  }

  Future<void> concluir() async {
    await _marcarComoVistoSeHouverUsuario();
    _encerrar();
  }

  Future<void> _marcarComoVistoSeHouverUsuario() async {
    final userId = _userIdAtivo;
    if (userId != null) {
      await storage.marcarComoVisto(userId);
    }
  }

  void _encerrar() {
    _passoAtualIndex = null;
    _userIdAtivo = null;
    notifyListeners();
  }
}
