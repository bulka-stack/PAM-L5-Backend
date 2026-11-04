/// Завершённая сессия повторения: ReviewSession(id, deckId, date, reviewedCount, correctCount).
class ReviewSession {
  final int id;
  final int deckId;
  final DateTime date;
  final int reviewedCount;
  final int correctCount;

  const ReviewSession(this.id, this.deckId, this.date, this.reviewedCount, this.correctCount);

  ReviewSession copyWith({int? id}) =>
      ReviewSession(id ?? this.id, deckId, date, reviewedCount, correctCount);
}
