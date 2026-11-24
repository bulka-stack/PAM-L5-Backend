import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'result.dart';
import 'token_store.dart';

/// register / login по контракту шаблона; token уходит в TokenStore.
class AuthApi {
  AuthApi(this.baseUrl, this.tokens, {http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStore tokens;
  final http.Client _client;
  static const _timeout = Duration(seconds: 8);

  Future<Result<void>> register(String email, String password, String name) =>
      _post('/auth/register', {'email': email, 'password': password, 'name': name});

  Future<Result<void>> login(String email, String password) =>
      _post('/auth/login', {'email': email, 'password': password});

  Future<void> logout() => tokens.clear();

  Future<Result<void>> _post(String path, Map<String, Object?> body) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout); // без timeout зависший сервер держал бы экран вечно
      if (res.statusCode != 200 && res.statusCode != 201) {
        return Err(apiMessage(res, login: true)); // слой 2: 400 / 401 / 409 из конверта
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      await tokens.save(data['token'] as String); // C9: setString
      return const Ok(null);
    } on http.ClientException {
      // слой 1: упавшая дорога (на Android/iOS это SocketException, обёрнутый пакетом http)
      return const Err('Нет сети — повторите попытку');
    } on TimeoutException {
      return const Err('Сервер не отвечает');
    } on FormatException {
      return const Err('Ответ не тот, что обещан'); // слой 3: тело-сюрприз
    } on TypeError {
      return const Err('Ответ не тот, что обещан');
    }
  }
}
