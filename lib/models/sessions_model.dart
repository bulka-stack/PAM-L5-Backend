import 'package:flutter/foundation.dart';

import '../data/result.dart';
import '../data/review_session.dart';
import '../data/session_repository.dart';

/// История сессий и вычисляемая статистика (экраны «Статистика» и «Профиль»).
class SessionsModel extends ChangeNotifier {
  SessionsModel(this._repository, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final SessionRepository _repository;
  final DateTime Function() _clock;

  static const xpPerCard = 10;
  static const dailyGoal = 20;

  bool _loading = false;
  String? _error;
  List<ReviewSession> _sessions = const [];

  bool get isLoading => _loading;
  String? get error => _error;

  /// Новые сверху.
  List<ReviewSession> get sessions =>
      List.unmodifiable(List.of(_sessions)..sort((a, b) => b.date.compareTo(a.date)));

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    switch (await _repository.fetchAll()) {
      case Ok(:final value):
        _sessions = value;
      case Err(:final msg):
        _error = msg;
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> add(ReviewSession draft) async {
    switch (await _repository.create(draft)) {
      case Ok(:final value):
        _sessions = [..._sessions, value];
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> remove(int id) async {
    switch (await _repository.delete(id)) {
      case Ok():
        _sessions = _sessions.where((s) => s.id != id).toList();
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  // ------------------------------------------------------------- статистика

  int get totalReviewed => _sessions.fold(0, (s, e) => s + e.reviewedCount);
  int get totalCorrect => _sessions.fold(0, (s, e) => s + e.correctCount);

  /// Процент правильных ответов за всё время.
  int get accuracy => totalReviewed == 0 ? 0 : (totalCorrect * 100 / totalReviewed).round();

  int get xp => totalReviewed * xpPerCard;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  int get reviewedToday {
    final today = _day(_clock());
    return _sessions.where((s) => _day(s.date) == today).fold(0, (n, s) => n + s.reviewedCount);
  }

  /// Серия: дни подряд с хотя бы одной сессией, заканчивая сегодня (или вчера).
  int get streakDays {
    final days = _sessions.map((s) => _day(s.date)).toSet();
    var day = _day(_clock());
    if (!days.contains(day)) day = DateTime(day.year, day.month, day.day - 1);
    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return streak;
  }

  /// Карточек за каждый из последних 7 дней (последний — сегодня).
  List<int> get weekActivity {
    final today = _day(_clock());
    return [
      for (var i = 6; i >= 0; i--)
        _sessions
            .where((s) => _day(s.date) == DateTime(today.year, today.month, today.day - i))
            .fold(0, (n, s) => n + s.reviewedCount),
    ];
  }

  /// Подписи дней недели для [weekActivity].
  List<String> get weekLabels {
    const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final today = _day(_clock());
    return [
      for (var i = 6; i >= 0; i--)
        names[DateTime(today.year, today.month, today.day - i).weekday - 1],
    ];
  }
}
