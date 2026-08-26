import 'package:flutter/foundation.dart';

import '../../feed/data/publicacoes_repository.dart';
import '../../feed/domain/publicacao.dart';

enum StatusDetalhe { carregando, carregado, erro }

class PublicacaoDetalheProvider extends ChangeNotifier {
  PublicacaoDetalheProvider({
    required this.publicacoesRepository,
    Publicacao? publicacaoInicial,
    String? publicacaoId,
  }) : assert(
         publicacaoInicial != null || publicacaoId != null,
         'Precisa de publicacao hidratada OU id',
       ),
       publicacao = publicacaoInicial,
       _publicacaoId = publicacaoId ?? publicacaoInicial!.id;

  final PublicacoesRepository publicacoesRepository;
  Publicacao? publicacao;
  final String _publicacaoId;

  StatusDetalhe status = StatusDetalhe.carregando;
  String? mensagemErro;
  bool _excluindo = false;
  bool get excluindo => _excluindo;

  Future<void> carregar() async {
    if (publicacao != null) {
      status = StatusDetalhe.carregado;
      notifyListeners();
      return;
    }

    status = StatusDetalhe.carregando;
    mensagemErro = null;
    notifyListeners();
    try {
      publicacao = await publicacoesRepository.buscarPorId(_publicacaoId);
      status = StatusDetalhe.carregado;
    } catch (e) {
      status = StatusDetalhe.erro;
      mensagemErro = e.toString();
    }
    notifyListeners();
  }

  Future<void> excluir() async {
    if (publicacao == null) return;
    _excluindo = true;
    notifyListeners();
    try {
      await publicacoesRepository.deletar(publicacao!.id);
    } finally {
      _excluindo = false;
      notifyListeners();
    }
  }
}
