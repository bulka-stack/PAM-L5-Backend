// In-memory реализации интерфейсов — только для тестов моделей (mock-а в приложении больше нет).
import 'package:study_cards/data/card_repository.dart';
import 'package:study_cards/data/deck.dart';
import 'package:study_cards/data/deck_repository.dart';
import 'package:study_cards/data/flashcard.dart';
import 'package:study_cards/data/result.dart';

class FakeDeckRepository implements DeckRepository {
  final decks = <Deck>[for (var i = 1; i <= 25; i++) Deck(i, 'Колода $i', 'Языки')];
  bool fail = false;

  @override
  Future<Result<List<Deck>>> fetchAll({int page = 1, int limit = 20, String? search}) async {
    if (fail) return const Err('Нет сети — повторите попытку');
    final found = decks.where((d) => search == null || d.name.contains(search)).toList();
    return Ok(found.skip((page - 1) * limit).take(limit).toList());
  }

  @override
  Future<Result<Deck>> fetchById(int id) async => Ok(decks.firstWhere((d) => d.id == id));

  @override
  Future<Result<Deck>> create(Deck deck) async {
    final d = deck.copyWith(id: 100 + decks.length);
    decks.add(d);
    return Ok(d);
  }

  @override
  Future<Result<Deck>> update(Deck deck) async => Ok(deck);

  @override
  Future<Result<void>> delete(int id) async {
    decks.removeWhere((d) => d.id == id);
    return const Ok(null);
  }
}

class FakeCardRepository implements CardRepository {
  FakeCardRepository(DateTime now) : cards = [Flashcard(1, 1, 'latency', 'задержка', 2.5, 0, now)];
  final List<Flashcard> cards;

  @override
  Future<Result<List<Flashcard>>> fetchAll({int? deckId}) async => Ok(List.of(cards));

  @override
  Future<Result<Flashcard>> fetchById(int id) async => Ok(cards.firstWhere((c) => c.id == id));

  @override
  Future<Result<Flashcard>> create(Flashcard card) async {
    final c = card.copyWith(id: 100 + cards.length);
    cards.add(c);
    return Ok(c);
  }

  @override
  Future<Result<Flashcard>> update(Flashcard card) async => Ok(card);

  @override
  Future<Result<void>> delete(int id) async => const Ok(null);
}
