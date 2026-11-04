import 'card_repository.dart';
import 'flashcard.dart';
import 'mock_database.dart';
import 'result.dart';

/// Карточки в памяти: задержка + авария, как у колод.
class MockCardRepository implements CardRepository {
  MockCardRepository(this._db);
  final MockDatabase _db;

  static const _errNotFound = 'Карточка не существует';

  @override
  Future<Result<List<Flashcard>>> fetchAll({int? deckId}) async {
    final err = await _db.network();
    if (err != null) return Err(err);
    return Ok(_db.cards.where((c) => deckId == null || c.deckId == deckId).toList());
  }

  @override
  Future<Result<Flashcard>> fetchById(int id) async {
    final err = await _db.network();
    if (err != null) return Err(err);
    final i = _db.cards.indexWhere((c) => c.id == id);
    if (i == -1) return const Err(_errNotFound);
    return Ok(_db.cards[i]);
  }

  @override
  Future<Result<Flashcard>> create(Flashcard card) async {
    final err = await _db.network();
    if (err != null) return Err(err);
    if (!_db.decks.any((d) => d.id == card.deckId)) return const Err('Колода не существует');
    final created = card.copyWith(id: _db.nextCardId++);
    _db.cards.add(created);
    return Ok(created);
  }

  @override
  Future<Result<Flashcard>> update(Flashcard card) async {
    final err = await _db.network();
    if (err != null) return Err(err);
    final i = _db.cards.indexWhere((c) => c.id == card.id);
    if (i == -1) return const Err(_errNotFound);
    _db.cards[i] = card;
    return Ok(card);
  }

  @override
  Future<Result<void>> delete(int id) async {
    final err = await _db.network();
    if (err != null) return Err(err);
    final before = _db.cards.length;
    _db.cards.removeWhere((c) => c.id == id);
    if (_db.cards.length == before) return const Err(_errNotFound);
    return const Ok(null);
  }
}
