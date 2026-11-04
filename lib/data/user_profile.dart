/// Пользователь (на L5 приходит из GET /me).
class UserProfile {
  final int id;
  final String name;
  final String email;

  const UserProfile(this.id, this.name, this.email);
}
