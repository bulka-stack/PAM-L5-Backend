import 'mock_database.dart';
import 'result.dart';
import 'user_profile.dart';
import 'user_repository.dart';

/// Текущий пользователь из mock-базы.
class MockUserRepository implements UserRepository {
  MockUserRepository(this._db);
  final MockDatabase _db;

  @override
  Future<Result<UserProfile>> fetchMe() async {
    final err = await _db.network();
    if (err != null) return Err(err);
    return Ok(_db.user);
  }
}
