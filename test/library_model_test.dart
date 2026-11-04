import 'package:flutter_test/flutter_test.dart';
import 'package:study_cards/data/flashcard.dart';
import 'package:study_cards/models/library_model.dart';
import 'package:study_cards/models/srs.dart';

import 'fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 4, 12);
  late FakeDeckRepository decks;
  late LibraryModel model;

  setUp(() async {
    decks = FakeDeckRepository();
    model = LibraryModel(decks, FakeCardRepository(now), clock: () => now);
    await model.load();
  });

  test('пагинация: 20 колод, затем ещё 5 приклеиваются', () async {
    expect(model.decks, hasLength(20));
    expect(model.hasMore, isTrue);
    await model.loadMore();
    expect(model.decks, hasLength(25));
    expect(model.hasMore, isFalse);
  });

  test('поиск сохраняется при retry', () async {
    await model.load(search: 'Колода 2');
    expect(model.decks.map((d) => d.name), everyElement(contains('Колода 2')));
    await model.load(); // retry без аргумента
    expect(model.search, 'Колода 2');
  });

  test('ошибка → error, retry → данные', () async {
    decks.fail = true;
    await model.load();
    expect(model.error, 'Нет сети — повторите попытку');
    decks.fail = false;
    await model.load();
    expect(model.error, isNull);
  });

  test('оценка в сессии планирует карточку по SRS', () async {
    final card = model.dueCards().single;
    expect(await model.review(card, Grade.good), isNull);
    expect(model.totalDue, 0);
    expect(model.cardById(1)!.intervalDays, 3);
  });

  test('новая карточка видна в счётчиках', () async {
    await model.addCard(Flashcard.draft(1, 'jitter', 'дрожание задержки', now));
    expect(model.cardCount(1), 2);
    expect(model.totalDue, 2);
  });
}
