import 'api_client.dart';
import 'deck.dart';
import 'deck_repository.dart';
import 'result.dart';

/// Вторая реализация интерфейса L4 — на http, к собственному backend-у.
class HttpDeckRepository implements DeckRepository {
  HttpDeckRepository(this._api);
  final ApiClient _api;

  @override
  Future<Result<List<Deck>>> fetchAll() => _api.send(
    'GET',
    '/decks',
    okStatus: 200,
    parse: (json) =>
        ((json as Map<String, dynamic>)['items'] as List) // конверт!
            .map((e) => Deck.fromJson(e as Map<String, dynamic>))
            .toList(),
  );

  @override
  Future<Result<Deck>> fetchById(int id) => _api.send(
    'GET',
    '/decks/$id', // 404 → apiMessage → «Запись не существует»
    okStatus: 200,
    parse: (json) => Deck.fromJson(json as Map<String, dynamic>),
  );

  @override
  Future<Result<Deck>> create(Deck deck) => _api.send(
    'POST',
    '/decks',
    body: deck.toJson(),
    okStatus: 201, // id даёт сервер
    parse: (json) => Deck.fromJson(json as Map<String, dynamic>),
  );

  @override
  Future<Result<Deck>> update(Deck deck) => _api.send(
    'PUT',
    '/decks/${deck.id}',
    body: deck.toJson(),
    okStatus: 200,
    parse: (json) => Deck.fromJson(json as Map<String, dynamic>),
  );

  @override
  Future<Result<void>> delete(int id) =>
      _api.send('DELETE', '/decks/$id', okStatus: 204, parse: (_) {});
}
