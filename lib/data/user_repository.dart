import 'result.dart';
import 'user_profile.dart';

/// Текущий пользователь: на L5 — GET /me.
abstract class UserRepository {
  Future<Result<UserProfile>> fetchMe();
}
