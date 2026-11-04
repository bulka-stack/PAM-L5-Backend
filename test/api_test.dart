import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_cards/data/api_client.dart';
import 'package:study_cards/data/api_message.dart';
import 'package:study_cards/data/deck.dart';
import 'package:study_cards/data/http_deck_repository.dart';
import 'package:study_cards/data/result.dart';
import 'package:study_cards/data/token_store.dart';

http.Response jsonRes(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object> err(String code) => {
  'error': {'code': code, 'message': 'english text'},
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'auth_token': 'tok'}));

  group('apiMessage: конверт ошибки переводится один раз', () {
    test('коды контракта', () {
      expect(
        apiMessage(jsonRes(err('VALIDATION_ERROR'), 400)),
        'Отправленные данные недействительны',
      );
      expect(apiMessage(jsonRes(err('EMAIL_TAKEN'), 409)), 'Аккаунт с этим email уже существует');
      expect(apiMessage(jsonRes(err('NOT_FOUND'), 404)), 'Запись не существует');
      expect(
        apiMessage(jsonRes(err('UNAUTHORIZED'), 401), login: true),
        'Неверный email или пароль',
      );
      expect(apiMessage(jsonRes(err('INTERNAL'), 500)), 'Ошибка сервера (INTERNAL)');
    });
    test('тело вне контракта (HTML 500)', () {
      expect(apiMessage(http.Response('<html>oops</html>', 500)), 'Ошибка сервера (500)');
    });
  });

  group('HttpDeckRepository: три слоя отказа → Err(msg)', () {
    HttpDeckRepository repo(MockClient client, {void Function()? on401}) => HttpDeckRepository(
      ApiClient('http://api', TokenStore(), client: client, onUnauthorized: on401),
    );

    test('200: конверт → список колод, Bearer и query на месте', () async {
      late http.Request seen;
      final r = await repo(
        MockClient((req) async {
          seen = req;
          return jsonRes({
            'items': [
              {'id': 7, 'name': 'SQL', 'subject': 'Программирование', 'cardCount': 3},
            ],
            'page': 2,
            'limit': 20,
            'total': 21,
          }, 200);
        }),
      ).fetchAll(page: 2, search: 'SQL');
      expect(seen.headers['Authorization'], 'Bearer tok');
      expect(seen.url.queryParameters, {'page': '2', 'limit': '20', 'search': 'SQL'});
      expect((r as Ok<List<Deck>>).value.single.cardCount, 3);
    });

    test('404 → «Запись не существует» (слой 2)', () async {
      final r = await repo(MockClient((_) async => jsonRes(err('NOT_FOUND'), 404))).fetchById(9);
      expect((r as Err).msg, 'Запись не существует');
    });

    test('нет сети → «Нет сети» (слой 1)', () async {
      final r = await repo(MockClient((_) async => throw http.ClientException('refused')))
          .fetchById(1);
      expect((r as Err).msg, 'Нет сети — повторите попытку');
    });

    test('тело-сюрприз → «Ответ не тот, что обещан» (слой 3)', () async {
      final html = await repo(MockClient((_) async => http.Response('<html/>', 200))).fetchById(1);
      expect((html as Err).msg, 'Ответ не тот, что обещан');
      final wrong = await repo(MockClient((_) async => jsonRes({'id': 'x'}, 200))).fetchById(1);
      expect((wrong as Err).msg, 'Ответ не тот, что обещан');
    });

    test('204 на DELETE — без jsonDecode пустого тела', () async {
      final r = await repo(MockClient((_) async => http.Response('', 204))).delete(1);
      expect(r, isA<Ok<void>>());
    });

    test('401 → token стёрт, корень извещён', () async {
      var called = false;
      final r = await repo(
        MockClient((_) async => jsonRes(err('UNAUTHORIZED'), 401)),
        on401: () => called = true,
      ).fetchAll();
      expect((r as Err).msg, 'Сессия истекла — войдите снова');
      expect(called, isTrue);
      expect(await TokenStore().read(), isNull);
    });
  });
}
