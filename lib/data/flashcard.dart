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
