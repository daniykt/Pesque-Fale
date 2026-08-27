class FormatadorDataConversa {
  const FormatadorDataConversa();

  static const List<String> _diasSemanaAbrev = [
    'seg',
    'ter',
    'qua',
    'qui',
    'sex',
    'sáb',
    'dom',
  ];

  static const List<String> _mesesPorExtenso = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  /// Formata a data conforme padrão WhatsApp:
  /// - Hoje → HH:mm
  /// - Ontem → 'Ontem'
  /// - Últimos 7 dias (mas antes de ontem) → dia da semana abreviado
  /// - Este ano → dd/MM
  /// - Anos anteriores → dd/MM/aa
  String formatar(DateTime data, {DateTime? agora}) {
    final ref = agora ?? DateTime.now();
    final refData = DateTime(ref.year, ref.month, ref.day);
    final dataDia = DateTime(data.year, data.month, data.day);
    final diffDias = refData.difference(dataDia).inDays;

    if (diffDias == 0) return _formatarHora(data);
    if (diffDias == 1) return 'Ontem';
    if (diffDias >= 2 && diffDias <= 6) {
      return _diasSemanaAbrev[data.weekday - 1];
    }
    if (data.year == ref.year) return _formatarDdMm(data);
    return _formatarDdMmAa(data);
  }

  /// Divisor de data entre grupos de mensagens do chat:
  /// - Hoje → 'Hoje'
  /// - Ontem → 'Ontem'
  /// - Demais → '28 de maio de 2026'
  String formatarDivisorData(DateTime data, {DateTime? agora}) {
    final ref = agora ?? DateTime.now();
    final refData = DateTime(ref.year, ref.month, ref.day);
    final dataDia = DateTime(data.year, data.month, data.day);
    final diffDias = refData.difference(dataDia).inDays;

    if (diffDias == 0) return 'Hoje';
    if (diffDias == 1) return 'Ontem';
    return '${data.day} de ${_mesesPorExtenso[data.month - 1]} de ${data.year}';
  }

  /// Hora exibida abaixo do texto da bolha de mensagem: 'HH:mm'.
  String formatarHora(DateTime d) => _formatarHora(d);

  String _formatarHora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _formatarDdMm(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  String _formatarDdMmAa(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${(d.year % 100).toString().padLeft(2, '0')}';
}
