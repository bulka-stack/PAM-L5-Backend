import 'package:flutter_test/flutter_test.dart';
import 'package:study_cards/data/flashcard.dart';
import 'package:study_cards/models/srs.dart';

void main() {
  final now = DateTime(2026, 11, 4, 15, 30);
  Flashcard card({double ease = 2.5, int interval = 10}) =>
      Flashcard(1, 1, 'latency', 'задержка', ease, interval, now);

  group('Правило SRS (упрощённый SM-2)', () {
    test('снова → интервал 1 день, ease − 0.2', () {
      final c = Srs.schedule(card(), Grade.again, now);
      expect(c.intervalDays, 1);
      expect(c.easeFactor, 2.3);
      expect(c.nextReviewAt, DateTime(2026, 11, 5));
    });

    test('хорошо → интервал × ease, ease не меняется', () {
      final c = Srs.schedule(card(), Grade.good, now);
      expect(c.intervalDays, 25); // 10 × 2.5
      expect(c.easeFactor, 2.5);
      expect(c.nextReviewAt, DateTime(2026, 11, 29));
    });

    test('легко → интервал × ease × 1.3', () {
      final c = Srs.schedule(card(), Grade.easy, now);
      expect(c.intervalDays, 33); // 10 × 2.5 × 1.3 = 32.5 → 33
    });

    test('новая карточка (интервал 0) считается от 1 дня', () {
      final draft = Flashcard.draft(1, 'a', 'b', now);
      expect(draft.easeFactor, 2.5);
      expect(Srs.nextInterval(draft, Grade.good), 3); // 1 × 2.5 → 3
      expect(Srs.nextInterval(draft, Grade.easy), 3); // 1 × 2.5 × 1.3 = 3.25 → 3
    });

    test('ease не опускается ниже 1.3', () {
      var c = card(ease: 1.4);
      c = Srs.schedule(c, Grade.again, now);
      expect(c.easeFactor, 1.3);
      c = Srs.schedule(c, Grade.again, now);
      expect(c.easeFactor, 1.3);
    });

    test('карточка к повторению, когда nextReviewAt наступил', () {
      expect(card().isDue(now), isTrue);
      final later = Srs.schedule(card(), Grade.good, now);
      expect(later.isDue(now), isFalse);
      expect(later.isDue(DateTime(2026, 11, 29)), isTrue);
    });
  });
}
