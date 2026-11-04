import 'dart:convert';

import 'package:http/http.dart' as http;

/// Конверт ошибки {"error": {"code", "message"}} → сообщение для человека, в одном месте.
/// Английский message на экран не попадает: решает стабильный code.
String apiMessage(http.Response res, {bool login = false}) {
  try {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final code = (body['error'] as Map<String, dynamic>)['code'] as String;
    return switch (code) {
      'VALIDATION_ERROR' => 'Отправленные данные недействительны',
      'UNAUTHORIZED' => login ? 'Неверный email или пароль' : 'Сессия истекла — войдите снова',
      'EMAIL_TAKEN' => 'Аккаунт с этим email уже существует',
      'NOT_FOUND' => 'Запись не существует',
      _ => 'Ошибка сервера ($code)',
    };
  } on FormatException {
    return 'Ошибка сервера (${res.statusCode})'; // тело вне контракта, напр. HTML 500
  } on TypeError {
    return 'Ошибка сервера (${res.statusCode})';
  }
}
