import 'deck.dart';
import 'deck_repository.dart';
import 'mock_database.dart';
import 'result.dart';

/// Колоды в памяти, с повадками сети: задержка + переключаемая авария.
class MockDeckRepository implements DeckRepository {
  MockDeckRepository(this._db);
  final MockDatabase _db;

  static const _errNotFound = 'Колода не существует';

  @override
  Future<Result<List<Deck>>> fetchAll() async {
    final err = await _db.network();
    if (err != null) return Err(err);
    return Ok(_db.decks.map(_db.withCount).toList()); // копия — внутренность не отдаётся
  }

  @override
  Future<Result<Deck>> fetchById(int id) async {
    final err = await _db.network();
    if (err != null) return Err(err);
    final i = _db.decks.indexWhere((d) => d.id == id);
    if (i == -1) return const Err(_errNotFound); // «404» mock-а
    return Ok(_db.withCount(_db.decks[i]));
  }

  @override
  Future<Result<Deck>> create(Deck deck) async {
    final err = await _db.network();
    if (err != null) return Err(err);
    final created = deck.copyWith(id: _db.nextDeckId++, cardCount: 0); // id даёт ХРАНИЛИЩЕ
    _db.decks.add(created);
    return Ok(created);
  }

  @override
  Future<Result<Deck>> update(Deck deck) async {
    final err = await _db.network();
    if (err != null) return Err(err);
    final i = _db.decks.indexWhere((d) => d.id == deck.id);
    if (i == -1) return const Err(_errNotFound);
    _db.decks[i] = deck;
    return Ok(_db.withCount(deck));
  }

  @override
  Future<Result<void>> delete(int id) async {
    final err = await _db.network();
    if (err != null) return Err(err);
    final before = _db.decks.length;
    _db.decks.removeWhere((d) => d.id == id);
    if (_db.decks.length == before) return const Err(_errNotFound);
    _db.cards.removeWhere((c) => c.deckId == id); // каскад, как ON DELETE CASCADE
    return const Ok(null); // «удалил, отдать нечего» — 204
  }
}
