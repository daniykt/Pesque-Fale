import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesque_fale_app/features/notificacoes/domain/notificacao.dart';
import 'package:pesque_fale_app/features/notificacoes/presentation/utils/texto_notificacao.dart';

const _base = TextStyle();
const _bold = TextStyle(fontWeight: FontWeight.bold);

Notificacao _seguindo({bool deVolta = false}) => Notificacao(
  id: 'notif-1',
  para: 'eu',
  deId: 'outro',
  de: 'Outro Pescador',
  tipo: TipoNotificacao.seguindo,
  lida: false,
  deVolta: deVolta,
  criadoEm: DateTime(2026),
);

void main() {
  group('spansDaNotificacao — seguindo', () {
    test('seguir de volta mostra "seguiu você de volta"', () {
      final spans = spansDaNotificacao(_seguindo(deVolta: true), _base, _bold);

      expect(spans[1].text, ' seguiu você de volta');
    });

    test('follow novo mostra "começou a seguir você"', () {
      final spans = spansDaNotificacao(_seguindo(), _base, _bold);

      expect(spans[1].text, ' começou a seguir você');
    });

    test('nome do autor continua em negrito no primeiro span', () {
      final spans = spansDaNotificacao(_seguindo(deVolta: true), _base, _bold);

      expect(spans.first.text, 'Outro Pescador');
      expect(spans.first.style, _bold);
    });
  });
}
