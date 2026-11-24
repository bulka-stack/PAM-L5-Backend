import 'api_client.dart';
import 'result.dart';
import 'user_profile.dart';
import 'user_repository.dart';

/// Текущий пользователь: GET /me.
class HttpUserRepository implements UserRepository {
  HttpUserRepository(this._api);
  final ApiClient _api;

  @override
  Future<Result<UserProfile>> fetchMe() => _api.send(
    'GET',
    '/me',
    okStatus: 200,
    parse: (json) => UserProfile.fromJson(json as Map<String, dynamic>),
  );
}
