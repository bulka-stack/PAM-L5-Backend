/// Маленькие помощники форматирования, общие для экранов.
library;

/// Русское склонение: plural(5, 'карточка', 'карточки', 'карточек') → 'карточек'.
String plural(int n, String one, String few, String many) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}

/// '12 карточек'.
String cardsLabel(int n) => '$n ${plural(n, 'карточка', 'карточки', 'карточек')}';

/// '3 дня'.
String daysLabel(int n) => '$n ${plural(n, 'день', 'дня', 'дней')}';

String _two(int v) => v.toString().padLeft(2, '0');

/// 04.11.2026
String formatDate(DateTime d) => '${_two(d.day)}.${_two(d.month)}.${d.year}';

/// 04.11
String formatShortDate(DateTime d) => '${_two(d.day)}.${_two(d.month)}';

/// 04.11.2026, 21:40
String formatDateTime(DateTime d) => '${formatDate(d)}, ${_two(d.hour)}:${_two(d.minute)}';

/// Процент правильных ответов: 15 из 18 → 83.
int percent(int part, int total) => total == 0 ? 0 : (part * 100 / total).round();
