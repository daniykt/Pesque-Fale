class FormatadorTempoRelativo {
  const FormatadorTempoRelativo();

  String formatar(DateTime data, {DateTime? agora}) {
    final ref = agora ?? DateTime.now();
    final diff = ref.difference(data);

    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays < 7) {
      return 'há ${diff.inDays} ${diff.inDays == 1 ? "dia" : "dias"}';
    }
    if (diff.inDays < 30) return 'há ${(diff.inDays / 7).floor()} sem';
    if (diff.inDays < 365) {
      final m = (diff.inDays / 30).floor();
      return 'há $m ${m == 1 ? "mês" : "meses"}';
    }
    final a = (diff.inDays / 365).floor();
    return 'há $a ${a == 1 ? "ano" : "anos"}';
  }
}
