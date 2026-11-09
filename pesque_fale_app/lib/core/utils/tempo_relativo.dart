class TempoRelativo {
  TempoRelativo._();

  static String formatar(DateTime data, {DateTime? agora}) {
    final diff = (agora ?? DateTime.now()).difference(data);

    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    if (diff.inDays < 7) {
      final dias = diff.inDays;
      return dias == 1 ? 'há 1 dia' : 'há $dias dias';
    }
    if (diff.inDays < 30) {
      final semanas = diff.inDays ~/ 7;
      return semanas == 1 ? 'há 1 semana' : 'há $semanas semanas';
    }

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }
}
