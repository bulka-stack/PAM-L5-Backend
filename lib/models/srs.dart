import '../data/flashcard.dart';

/// Оценка карточки в сессии повторения.
enum Grade { again, good, easy }

/// Правило интервального повторения — упрощённый SM-2 из ТЗ темы:
///   снова  → интервал = 1 день, ease − 0.2;
///   хорошо → интервал × ease;
///   легко  → интервал × ease × 1.3;
/// начальный ease 2.5. Чистая логика без виджетов — тестируется без UI.
class Srs {
  static const minEase = 1.3; // нижняя граница ease, как в оригинальном SM-2
  static const easeStep = 0.2;
  static const easyBonus = 1.3;

  /// Новый интервал в днях для оценки [grade].
  static int nextInterval(Flashcard card, Grade grade) {
    final base = card.intervalDays < 1 ? 1 : card.intervalDays; // у новой карточки интервал 0
    final days = switch (grade) {
      Grade.again => 1,
      Grade.good => base * card.easeFactor,
      Grade.easy => base * card.easeFactor * easyBonus,
    };
    final rounded = days.round();
    return rounded < 1 ? 1 : rounded;
  }

  /// Новый ease: снижается только при «снова».
  static double nextEase(Flashcard card, Grade grade) {
    if (grade != Grade.again) return card.easeFactor;
    final ease = card.easeFactor - easeStep;
    return ease < minEase ? minEase : double.parse(ease.toStringAsFixed(2));
  }

  /// Планирование: карточка с новым ease, интервалом и nextReviewAt
  /// (полночь дня, наступающего через интервал).
  static Flashcard schedule(Flashcard card, Grade grade, DateTime now) {
    final interval = nextInterval(card, grade);
    return card.copyWith(
      easeFactor: nextEase(card, grade),
      intervalDays: interval,
      nextReviewAt: DateTime(now.year, now.month, now.day + interval),
    );
  }
}
