import 'package:flutter/foundation.dart';

import '../../feed/data/eventos_exceptions.dart';
import '../../feed/data/eventos_repository.dart';
import '../../feed/domain/evento.dart';

enum StatusEventoDetalhe { carregando, carregado, naoEncontrado, erro }

class EventoDetalheProvider extends ChangeNotifier {
  EventoDetalheProvider({
    required this.repository,
    Evento? eventoInicial,
    String? eventoId,
  }) : assert(eventoInicial != null || eventoId != null),
       eventoId = eventoId ?? eventoInicial!.id,
       _evento = eventoInicial,
       status = eventoInicial != null
           ? StatusEventoDetalhe.carregado
           : StatusEventoDetalhe.carregando;

  final EventosRepository repository;
  final String eventoId;

  Evento? _evento;
  Evento? get evento => _evento;

  StatusEventoDetalhe status;
  String? mensagemErro;
  bool _excluindo = false;
  bool get excluindo => _excluindo;
  bool _carregando = false;
  bool _descartado = false;

  bool ehOrganizador(String? usuarioId) =>
      usuarioId != null && _evento?.organizadorId == usuarioId;

  Future<void> carregar() async {
    if (_carregando) return;
    _carregando = true;
    final temEvento = _evento != null;
    if (!temEvento) {
      status = StatusEventoDetalhe.carregando;
      mensagemErro = null;
      _notificar();
    }
    try {
      _evento = await repository.buscarPorId(eventoId);
      status = StatusEventoDetalhe.carregado;
      mensagemErro = null;
    } on EventoNaoEncontradoException {
      _evento = null;
      status = StatusEventoDetalhe.naoEncontrado;
    } catch (e) {
      if (!temEvento) {
        status = StatusEventoDetalhe.erro;
        mensagemErro = e is EventosException
            ? e.message
            : 'Não foi possível carregar o evento.';
      }
    } finally {
      _carregando = false;
    }
    _notificar();
  }

  void atualizar(Evento editado) {
    if (editado.id != eventoId) return;
    _evento = editado;
    status = StatusEventoDetalhe.carregado;
    _notificar();
  }

  Future<bool> excluir() async {
    if (_excluindo || _evento == null) return false;
    _excluindo = true;
    mensagemErro = null;
    _notificar();
    try {
      await repository.excluir(eventoId);
      return true;
    } on EventoNaoEncontradoException {
      return true;
    } on EventosException catch (e) {
      mensagemErro = e.message;
      return false;
    } catch (_) {
      mensagemErro = 'Não foi possível excluir o evento. Tente novamente.';
      return false;
    } finally {
      _excluindo = false;
      _notificar();
    }
  }

  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
