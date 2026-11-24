import 'api_client.dart';
import 'card_repository.dart';
import 'flashcard.dart';
import 'result.dart';

/// Карточки на http: GET/POST /cards, GET/PUT/DELETE /cards/{id}.
class HttpCardRepository implements CardRepository {
  HttpCardRepository(this._api);
  final ApiClient _api;

  @override
  Future<Result<List<Flashcard>>> fetchAll({int? deckId}) => _api.fetchAllPages(
    '/cards',
    Flashcard.fromJson,
    query: {if (deckId != null) 'deckId': '$deckId'},
  );

  @override
  Future<Result<Flashcard>> fetchById(int id) => _api.send(
    'GET',
    '/cards/$id',
    okStatus: 200,
    parse: (json) => Flashcard.fromJson(json as Map<String, dynamic>),
  );

  @override
  Future<Result<Flashcard>> create(Flashcard card) => _api.send(
    'POST',
    '/cards',
    body: card.toJson(),
    okStatus: 201,
    parse: (json) => Flashcard.fromJson(json as Map<String, dynamic>),
  );

  /// PUT /cards/{id} — и правка сторон, и обновление расписания после оценки.
  @override
  Future<Result<Flashcard>> update(Flashcard card) => _api.send(
    'PUT',
    '/cards/${card.id}',
    body: card.toJson(),
    okStatus: 200,
    parse: (json) => Flashcard.fromJson(json as Map<String, dynamic>),
  );

  @override
  Future<Result<void>> delete(int id) =>
      _api.send('DELETE', '/cards/$id', okStatus: 204, parse: (_) {});
}
