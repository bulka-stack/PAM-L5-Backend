import 'package:flutter_test/flutter_test.dart';
import 'package:study_cards/data/deck.dart';
import 'package:study_cards/data/flashcard.dart';
import 'package:study_cards/data/mock_card_repository.dart';
import 'package:study_cards/data/mock_database.dart';
import 'package:study_cards/data/mock_deck_repository.dart';
import 'package:study_cards/models/library_model.dart';
import 'package:study_cards/models/srs.dart';

void main() {
  late MockDatabase db;
  late LibraryModel model;
  var notifications = 0;

  setUp(() async {
    db = MockDatabase();
    model = LibraryModel(MockDeckRepository(db), MockCardRepository(db));
    notifications = 0;
    model.addListener(() => notifications++);
    await model.load();
  });

  test('load: триада loading → data, коллекции только для чтения', () {
    expect(model.isLoading, isFalse);
    expect(model.error, isNull);
    expect(model.decks, hasLength(8));
    expect(notifications, 2); // «грузится» и «готово»
    expect(() => model.decks.add(const Deck(99, 'x', 'y')), throwsUnsupportedError);
  });

  test('новая карточка: id даёт хранилище, счётчики и «к повторению» растут', () async {
    final before = model.cardCount(1);
    final dueBefore = model.totalDue;
    final err = await model.addCard(
      Flashcard.draft(1, 'scalability', 'масштабируемость', model.now),
    );
    expect(err, isNull);
    expect(model.cardCount(1), before + 1);
    expect(model.totalDue, dueBefore + 1);
    expect(model.cardsOf(1).last.id, greaterThanOrEqualTo(1000));
  });

  test('оценка «хорошо» убирает карточку из очереди на сегодня', () async {
    final card = model.dueCards(deckId: 1).first;
    final err = await model.review(card, Grade.good);
    expect(err, isNull);
    expect(model.dueCards(deckId: 1).any((c) => c.id == card.id), isFalse);
  });

  test('удаление колоды удаляет и её карточки', () async {
    expect(await model.removeDeck(2), isNull);
    expect(model.deckById(2), isNull);
    expect(model.cardsOf(2), isEmpty);
  });

  test('авария: Err вместо данных, состояние не тронуто', () async {
    db.simulateError = true;
    final err = await model.addDeck(const Deck(0, 'Новая', 'Языки'));
    expect(err, MockDatabase.errNetwork);
    expect(model.decks, hasLength(8));
    await model.load();
    expect(model.error, MockDatabase.errNetwork);
    db.simulateError = false;
    await model.load();
    expect(model.error, isNull);
  });
}
