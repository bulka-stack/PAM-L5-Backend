/// Флеш-карточка: Card(id, deckId, front, back, easeFactor, nextReviewAt) + текущий интервал.
/// intervalDays нужен алгоритму SM-2: новый интервал = старый × ease.
/// (Класс не называется Card, чтобы не конфликтовать с виджетом Card из Material.)
class Flashcard {
  final int id;
  final int deckId;
  final String front;
  final String back;
  final double easeFactor;
  final int intervalDays;
  final DateTime nextReviewAt;

  const Flashcard(
    this.id,
    this.deckId,
    this.front,
    this.back,
    this.easeFactor,
    this.intervalDays,
    this.nextReviewAt,
  );

  static const initialEase = 2.5;

  /// Новая карточка: ease 2.5, интервал 0, к повторению — сразу.
  factory Flashcard.draft(int deckId, String front, String back, DateTime now) =>
      Flashcard(0, deckId, front, back, initialEase, 0, now);

  /// Граница JSON (L5). Даты приходят в UTC (ISO-8601) — переводим в локальное время.
  factory Flashcard.fromJson(Map<String, dynamic> j) => Flashcard(
    j['id'] as int,
    j['deckId'] as int,
    j['front'] as String,
    j['back'] as String,
    (j['easeFactor'] as num).toDouble(), // JSON: 2.5, но 3 приходит как int!
    (j['intervalDays'] as num).toInt(),
    DateTime.parse(j['nextReviewAt'] as String).toLocal(),
  );

  Map<String, dynamic> toJson() => {
    'deckId': deckId,
    'front': front,
    'back': back,
    'easeFactor': easeFactor,
    'intervalDays': intervalDays,
    'nextReviewAt': nextReviewAt.toUtc().toIso8601String(),
  };

  /// Карточка к повторению, если её дата уже наступила.
  bool isDue(DateTime now) => !nextReviewAt.isAfter(now);

  /// «Выучено»: интервал не меньше трёх недель.
  bool get isLearned => intervalDays >= 21;

  Flashcard copyWith({
    int? id,
    String? front,
    String? back,
    double? easeFactor,
    int? intervalDays,
    DateTime? nextReviewAt,
  }) => Flashcard(
    id ?? this.id,
    deckId,
    front ?? this.front,
    back ?? this.back,
    easeFactor ?? this.easeFactor,
    intervalDays ?? this.intervalDays,
    nextReviewAt ?? this.nextReviewAt,
  );
}
