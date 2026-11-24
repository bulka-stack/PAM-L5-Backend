import 'package:flutter/foundation.dart';

import '../data/result.dart';
import '../data/user_profile.dart';
import '../data/user_repository.dart';

/// Текущий пользователь (экран профиля).
class UserModel extends ChangeNotifier {
  UserModel(this._repository);
  final UserRepository _repository;

  bool _loading = false;
  String? _error;
  UserProfile? _user;

  bool get isLoading => _loading;
  String? get error => _error;
  UserProfile? get user => _user;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    switch (await _repository.fetchMe()) {
      case Ok(:final value):
        _user = value;
      case Err(:final msg):
        _error = msg;
    }
    _loading = false;
    notifyListeners();
  }
}
