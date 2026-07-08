class TempoRelativo {
  TempoRelativo._();

  static String formatar(DateTime data, {DateTime? agora}) {
    final diff = (agora ?? DateTime.now()).difference(data);

    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    if (diff.inDays < 7) return 'há ${diff.inDays} dias';
    if (diff.inDays < 30) return 'há ${(diff.inDays / 7).floor()} semanas';

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }
}
