/// Пользователь (на L5 приходит из GET /me).
class UserProfile {
  final int id;
  final String name;
  final String email;

  const UserProfile(this.id, this.name, this.email);

  factory UserProfile.fromJson(Map<String, dynamic> j) =>
      UserProfile(j['id'] as int, j['name'] as String, j['email'] as String);
}
