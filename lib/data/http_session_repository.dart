import 'api_client.dart';
import 'result.dart';
import 'review_session.dart';
import 'session_repository.dart';

/// История сессий на http: GET/POST /review-sessions, DELETE /review-sessions/{id}.
class HttpSessionRepository implements SessionRepository {
  HttpSessionRepository(this._api);
  final ApiClient _api;

  @override
  Future<Result<List<ReviewSession>>> fetchAll() =>
      _api.fetchAllPages('/review-sessions', ReviewSession.fromJson);

  @override
  Future<Result<ReviewSession>> create(ReviewSession session) => _api.send(
    'POST',
    '/review-sessions',
    body: session.toJson(),
    okStatus: 201,
    parse: (json) => ReviewSession.fromJson(json as Map<String, dynamic>),
  );

  @override
  Future<Result<void>> delete(int id) =>
      _api.send('DELETE', '/review-sessions/$id', okStatus: 204, parse: (_) {});
}
