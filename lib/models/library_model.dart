import 'package:flutter/foundation.dart';

import '../data/card_repository.dart';
import '../data/deck.dart';
import '../data/deck_repository.dart';
import '../data/flashcard.dart';
import '../data/result.dart';
import 'srs.dart';

/// Разделяемое состояние «библиотеки»: колоды и их карточки.
/// Читают несколько экранов (колоды, колода, формы, сессия, бейджи) — поэтому оно здесь,
/// а не в setState. Хранилища входят через конструктор (DI): модель не знает, mock это или http.
class LibraryModel extends ChangeNotifier {
  LibraryModel(this._decks, this._cards, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DeckRepository _decks; // тип — ИНТЕРФЕЙС, а не mock!
  final CardRepository _cards;
  final DateTime Function() _clock;

  static const pageSize = 20;

  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String _search = '';
  String? _error;
  List<Deck> _deckList = const [];
  List<Flashcard> _cardList = const [];

  bool get isLoading => _loading;
  bool get hasMore => _hasMore; // полная страница → видимо, есть ещё
  String get search => _search;
  String? get error => _error;
  List<Deck> get decks => List.unmodifiable(_deckList);
  List<Flashcard> get cards => List.unmodifiable(_cardList);
  DateTime get now => _clock();

  /// Загрузка: триада loading / data / error (C8) как состояние модели.
  /// L5: [search] — фильтр на сервере; retry без аргумента сохраняет прежний фильтр.
  Future<void> load({String? search}) async {
    _search = search ?? _search;
    _page = 1;
    _loading = true;
    _error = null;
    notifyListeners(); // подписанные экраны входят в «грузится»

    final (decks, cards) = await (
      _decks.fetchAll(page: 1, limit: pageSize, search: _search),
      _cards.fetchAll(),
    ).wait;
    switch ((decks, cards)) {
      case (Ok(value: final d), Ok(value: final c)):
        _deckList = d;
        _cardList = c;
        _hasMore = d.length == pageSize;
      case (Err(:final msg), _) || (_, Err(:final msg)):
        _error = msg;
    }
    _loading = false;
    notifyListeners(); // …и выходят: с данными или с ошибкой — никогда молча
  }

  /// Следующая страница колод — её просит хвост списка.
  /// Стартует из itemBuilder, в разгар build: поэтому _loadingMore = true БЕЗ notifyListeners.
  Future<void> loadMore() async {
    if (_loadingMore || _loading || !_hasMore) return; // guard: без него — дубли страниц
    _loadingMore = true;
    final result = await _decks.fetchAll(page: _page + 1, limit: pageSize, search: _search);
    switch (result) {
      case Ok(:final value):
        _page += 1;
        _deckList = [..._deckList, ...value]; // страница ПРИКЛЕИВАЕТСЯ
        _hasMore = value.length == pageSize;
      case Err(:final msg):
        _error = msg;
    }
    _loadingMore = false;
    notifyListeners();
  }

  // ------------------------------------------------------------- запросы

  Deck? deckById(int id) => _deckList.where((d) => d.id == id).firstOrNull;
  Flashcard? cardById(int id) => _cardList.where((c) => c.id == id).firstOrNull;

  List<Flashcard> cardsOf(int deckId) => _cardList.where((c) => c.deckId == deckId).toList();

  /// Карточки к повторению: всех колод ([deckId] == null) или одной.
  List<Flashcard> dueCards({int? deckId}) {
    final t = now;
    return _cardList.where((c) => (deckId == null || c.deckId == deckId) && c.isDue(t)).toList()
      ..sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));
  }

  int cardCount(int deckId) => _cardList.where((c) => c.deckId == deckId).length;
  int dueCount(int deckId) => dueCards(deckId: deckId).length;
  int learnedCount(int deckId) => _cardList.where((c) => c.deckId == deckId && c.isLearned).length;
  int get totalDue => dueCards().length;

  // ------------------------------------------------------------- мутации
  // Конвенция: null — успех, строка — сообщение об ошибке (как у validator).

  Future<String?> addDeck(Deck draft) async {
    switch (await _decks.create(draft)) {
      case Ok(:final value):
        _deckList = [..._deckList, value]; // с id, полученным от хранилища
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg; // состояние нетронуто — экран решает, что показать
    }
  }

  Future<String?> updateDeck(Deck deck) async {
    switch (await _decks.update(deck)) {
      case Ok(:final value):
        _deckList = [for (final d in _deckList) d.id == value.id ? value : d];
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> removeDeck(int id) async {
    switch (await _decks.delete(id)) {
      case Ok():
        _deckList = _deckList.where((d) => d.id != id).toList();
        _cardList = _cardList.where((c) => c.deckId != id).toList(); // карточки уходят с колодой
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> addCard(Flashcard draft) async {
    switch (await _cards.create(draft)) {
      case Ok(:final value):
        _cardList = [..._cardList, value];
        notifyListeners(); // список колоды, счётчики, бейдж «к повторению» — узнают все
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> updateCard(Flashcard card) async {
    switch (await _cards.update(card)) {
      case Ok(:final value):
        _cardList = [for (final c in _cardList) c.id == value.id ? value : c];
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> removeCard(int id) async {
    switch (await _cards.delete(id)) {
      case Ok():
        _cardList = _cardList.where((c) => c.id != id).toList();
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  /// Оценка в сессии: правило SRS планирует nextReviewAt, хранилище сохраняет расписание.
  Future<String?> review(Flashcard card, Grade grade) => updateCard(Srs.schedule(card, grade, now));
}

/// Имя колоды для истории сессий: пока колоды не загружены — «Колода №id»,
/// если загружены, но такой нет — значит, её удалили.
String deckTitle(LibraryModel library, int deckId) =>
    library.deckById(deckId)?.name ??
    (library.decks.isEmpty ? 'Колода №$deckId' : 'Удалённая колода');
