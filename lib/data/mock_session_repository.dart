import 'mock_database.dart';
import 'result.dart';
import 'review_session.dart';
import 'session_repository.dart';

/// История сессий в памяти: задержка + авария.
class MockSessionRepository implements SessionRepository {
  MockSessionRepository(this._db);
  final MockDatabase _db;

  @override
  Future<Result<List<ReviewSession>>> fetchAll() async {
    final err = await _db.network();
    if (err != null) return Err(err);
    return Ok(List.of(_db.sessions));
  }

  @override
  Future<Result<ReviewSession>> create(ReviewSession session) async {
    final err = await _db.network();
    if (err != null) return Err(err);
    final created = session.copyWith(id: _db.nextSessionId++);
    _db.sessions.add(created);
    return Ok(created);
  }

  @override
  Future<Result<void>> delete(int id) async {
    final err = await _db.network();
    if (err != null) return Err(err);
    final before = _db.sessions.length;
    _db.sessions.removeWhere((s) => s.id == id);
    if (_db.sessions.length == before) return const Err('Сессия не существует');
    return const Ok(null);
  }
}
