# StudyCards — флеш-карточки с интервальным повторением

Проект дисциплины PAM, тема **T13 StudyCards** (сложность: повышенная).
Автор: Andrii Kostin, группа TI-235. Преподаватель: унив. лектор Ionel Antohi.

**Этап L5 — интеграция с собственным backend-ом.** Проект продолжает L4 (та же история git).
Backend — порт Node.js шаблона курса в папке `server/`, расширенный сущностями темы.
Mock-хранилища удалены; источник данных сменён только в корне композиции `main.dart`.

## 1. Запуск backend-а

Нужен Node.js ≥ 22.13 (используется встроенный `node:sqlite`).

```bash
cd server
npm install        # один раз (express, multer)
npm start          # → http://localhost:8080, app.db создаётся сам
```

Во втором терминале:

```bash
cd server
npm run check      # контрактный тест: базовый контракт шаблона + маршруты темы (33 проверки)
npm run seed       # демо-данные: andrii.kostin@isa.utm.md / parola123, 24 колоды, 8 сессий
```

Маршруты темы (все под `requireAuth`, ошибки — в стандартном конверте):

| Метод | Адрес | Описание |
|---|---|---|
| GET / POST | `/decks` | список колод (`page`, `limit`, `search`) / создание; `cardCount` считает сервер |
| GET / PUT / DELETE | `/decks/{id}` | колода; DELETE удаляет и её карточки |
| GET / POST | `/cards` | список (`deckId`, `page`, `limit`, `search`) / создание (ease 2,5) |
| GET / PUT / DELETE | `/cards/{id}` | PUT — и правка сторон, и расписание SRS |
| GET / POST | `/review-sessions` | история / новая сессия (`correctCount ≤ reviewedCount`) |
| DELETE | `/review-sessions/{id}` | удаление сессии |

## 2. Запуск приложения

```bash
flutter pub get
flutter run                                         # эмулятор: сервер = http://10.0.2.2:8080
flutter run --dart-define=API_BASE=http://192.168.x.x:8080   # физический телефон
flutter test
```

Android: в `AndroidManifest.xml` добавлены `INTERNET` и `usesCleartextTraffic` (сервер — по HTTP).

## Что изменилось относительно L4

- `lib/data/token_store.dart` — JWT в `shared_preferences` (пароль не хранится никогда).
- `lib/data/api_message.dart` — конверт ошибки → русское сообщение (один `switch`).
- `lib/data/auth_api.dart` — register / login; `lib/data/api_client.dart` — общий скелет
  запроса: Bearer, timeout, три слоя отказа → `Err(msg)`, поток 401 (token стёрт → login).
- `lib/data/http_*_repository.dart` — вторые реализации интерфейсов L4.
- `main.dart` — async: запуск решает по token-у; mock заменён на http.
- Задание 6: `fetchAll({page, limit, search})`, `LibraryModel.load(search:)` + `loadMore()`,
  поиск в «Моих колодах» — на сервере, хвост списка подгружает страницы.

Доказательство «экраны не тронуты» (коммит замены источника против последнего коммита L4):

```bash
git diff --stat <коммит README L4> <коммит «Mock умирает»> -- lib/screens lib/models
# изменены только login_screen.dart и profile_screen.dart — легитимные исключения
```

## Что показать на защите

1. `npm start`, `npm run check` (PASS 33/33), `npm run seed`.
2. Вход с неверным паролем → «Неверный email или пароль»; регистрация на занятый email →
   «Аккаунт с этим email уже существует».
3. Верный вход → колоды с сервера; прокрутка вниз → подгружается вторая страница.
4. Поиск «Английский» + Enter → фильтр на сервере (`GET /decks?search=`).
5. Новая карточка → `POST /cards` (id от сервера), счётчики выросли.
6. Остановить сервер → потянуть список → экран ошибки → запустить → «Повторить».
7. Перезапустить сервер с `JWT_SECRET=alt-secret` → первый запрос даёт 401 → приложение
   само возвращается на login (token стёрт).
8. Закрыть и открыть приложение → сразу колоды (token пережил перезапуск); профиль → «Выйти».
