import 'deck.dart';
import 'result.dart';

/// Контракт: ЧТО можно просить у хранилища колод, а не КАК.
/// На L5 каждый метод отображается на REST: GET/POST /decks, GET/PUT/DELETE /decks/{id}.
abstract class DeckRepository {
  /// L5, Задание 6: интерфейс растёт совместимо — старый вызов fetchAll() компилируется.
  Future<Result<List<Deck>>> fetchAll({int page = 1, int limit = 20, String? search});
  Future<Result<Deck>> fetchById(int id);
  Future<Result<Deck>> create(Deck deck);
  Future<Result<Deck>> update(Deck deck);
  Future<Result<void>> delete(int id);
}
