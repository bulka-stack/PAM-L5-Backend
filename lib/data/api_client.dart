import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'result.dart';
import 'token_store.dart';

/// Общий «скелет» запроса для всех http-хранилищ: Bearer-заголовок, timeout,
/// три слоя отказа (C8) → Err(msg) и поток 401 (C9) — написан один раз.
class ApiClient {
  ApiClient(this.baseUrl, this.tokens, {this.onUnauthorized, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStore tokens;

  /// Что делать при 401 — решает корень композиции (назад на login); хранилище не знает router.
  final void Function()? onUnauthorized;
  final http.Client _client;

  static const _timeout = Duration(seconds: 8);

  Future<Map<String, String>> _headers() async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await tokens.read() ?? ''}', // C8: Bearer
  };

  /// 401 = пропуск умер: token выбрасывается (C9), корень навигирует.
  Future<String> _sessionDied() async {
    await tokens.clear();
    onUnauthorized?.call();
    return 'Сессия истекла — войдите снова';
  }

  /// [okStatus] — «хороший» статус глагола: 200 GET/PUT, 201 POST, 204 DELETE.
  /// [parse] получает разобранный JSON (для 204 — null: на пустом теле jsonDecode не зовём).
  Future<Result<T>> send<T>(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    required int okStatus,
    required T Function(Object? json) parse,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
      final req = http.Request(method, uri)..headers.addAll(await _headers());
      if (body != null) req.body = jsonEncode(body);
      final res = await http.Response.fromStream(await _client.send(req).timeout(_timeout));

      if (res.statusCode == 401) return Err(await _sessionDied());
      if (res.statusCode != okStatus) return Err(apiMessage(res)); // слой 2: дурная весть
      if (res.statusCode == 204) return Ok(parse(null)); // пустое тело — без jsonDecode
      return Ok(parse(jsonDecode(res.body))); // конверт / объект → fromJson
    } on http.ClientException {
      return const Err('Нет сети — повторите попытку'); // слой 1: упавшая дорога
    } on TimeoutException {
      return const Err('Сервер не отвечает');
    } on FormatException {
      return const Err('Ответ не тот, что обещан'); // слой 3: тело-сюрприз (jsonDecode)
    } on TypeError {
      return const Err('Ответ не тот, что обещан'); // слой 3: cast-ы в fromJson
    }
  }

  /// Читает из пагинированного конверта {items, page, limit, total} все страницы подряд.
  Future<Result<List<T>>> fetchAllPages<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, String> query = const {},
  }) async {
    const limit = 100; // максимум контракта
    final all = <T>[];
    for (var page = 1; ; page++) {
      final result = await send<(List<T>, int)>(
        'GET',
        path,
        query: {...query, 'page': '$page', 'limit': '$limit'},
        okStatus: 200,
        parse: (json) {
          final env = json as Map<String, dynamic>;
          final items = (env['items'] as List)
              .map((e) => fromJson(e as Map<String, dynamic>))
              .toList();
          return (items, env['total'] as int);
        },
      );
      switch (result) {
        case Ok(value: (final items, final total)):
          all.addAll(items);
          if (items.length < limit || all.length >= total) return Ok(all);
        case Err(:final msg):
          return Err(msg);
      }
    }
  }
}
