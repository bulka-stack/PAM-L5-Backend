/// Завершённая сессия повторения: ReviewSession(id, deckId, date, reviewedCount, correctCount).
class ReviewSession {
  final int id;
  final int deckId;
  final DateTime date;
  final int reviewedCount;
  final int correctCount;

  const ReviewSession(this.id, this.deckId, this.date, this.reviewedCount, this.correctCount);

  factory ReviewSession.fromJson(Map<String, dynamic> j) => ReviewSession(
    j['id'] as int,
    j['deckId'] as int,
    DateTime.parse(j['date'] as String).toLocal(),
    (j['reviewedCount'] as num).toInt(),
    (j['correctCount'] as num).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'deckId': deckId,
    'date': date.toUtc().toIso8601String(),
    'reviewedCount': reviewedCount,
    'correctCount': correctCount,
  };

  ReviewSession copyWith({int? id}) =>
      ReviewSession(id ?? this.id, deckId, date, reviewedCount, correctCount);
}
