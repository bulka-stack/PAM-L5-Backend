import 'flashcard.dart';
import 'result.dart';

/// Контракт хранилища карточек: GET/POST /cards, GET/PUT/DELETE /cards/{id}.
/// update — это и обновление расписания (PUT /cards/{id}) после оценки в сессии.
abstract class CardRepository {
  Future<Result<List<Flashcard>>> fetchAll({int? deckId});
  Future<Result<Flashcard>> fetchById(int id);
  Future<Result<Flashcard>> create(Flashcard card);
  Future<Result<Flashcard>> update(Flashcard card);
  Future<Result<void>> delete(int id);
}
