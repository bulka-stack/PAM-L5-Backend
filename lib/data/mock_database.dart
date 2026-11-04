import 'deck.dart';
import 'flashcard.dart';
import 'mock_data.dart';
import 'review_session.dart';
import 'user_profile.dart';

/// «Сервер в памяти» для трёх mock-хранилищ: таблицы, счётчики id, задержка и авария.
/// Колоды, карточки и сессии лежат вместе, как в одной базе backend-а: удаление колоды
/// каскадно удаляет её карточки, а cardCount считается при каждом чтении.
class MockDatabase {
  MockDatabase({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    decks = List.of(seedDecks);
    cards = seedCards(today);
    sessions = seedSessions(today);
  }

  final DateTime Function() _clock;

  late List<Deck> decks;
  late List<Flashcard> cards;
  late List<ReviewSession> sessions;
  UserProfile user = seedUser;

  int nextDeckId = 1000; // выше любого id из seed-а
  int nextCardId = 1000;
  int nextSessionId = 1000;

  /// Авария: включена → любой вызов любого mock-хранилища проваливается.
  /// Переключается в профиле («Симулировать сбой сети») — леса демонстрации, умирают на L5.
  bool simulateError = false;

  static const latency = Duration(milliseconds: 800);
  static const errNetwork = 'Сервер не отвечает — повторите попытку';

  /// Пролог каждого метода: сеть не отвечает мгновенно — и мы не будем.
  /// Возвращает текст ошибки, если авария включена, иначе null.
  Future<String?> network() async {
    await Future.delayed(latency);
    return simulateError ? errNetwork : null;
  }

  Deck withCount(Deck d) => d.copyWith(cardCount: cards.where((c) => c.deckId == d.id).length);
}
