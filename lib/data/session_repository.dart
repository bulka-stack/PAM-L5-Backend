import 'result.dart';
import 'review_session.dart';

/// Контракт хранилища сессий: GET/POST /review-sessions, DELETE /review-sessions/{id}.
abstract class SessionRepository {
  Future<Result<List<ReviewSession>>> fetchAll();
  Future<Result<ReviewSession>> create(ReviewSession session);
  Future<Result<void>> delete(int id);
}
