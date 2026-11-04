import 'deck.dart';
import 'result.dart';

/// Контракт: ЧТО можно просить у хранилища колод, а не КАК.
/// На L5 каждый метод отображается на REST: GET/POST /decks, GET/PUT/DELETE /decks/{id}.
abstract class DeckRepository {
  Future<Result<List<Deck>>> fetchAll();
  Future<Result<Deck>> fetchById(int id);
  Future<Result<Deck>> create(Deck deck);
  Future<Result<Deck>> update(Deck deck);
  Future<Result<void>> delete(int id);
}
