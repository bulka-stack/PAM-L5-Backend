/// Колода карточек (модель данных темы: Deck(id, userId, name, subject, cardCount)).
/// cardCount считает хранилище (на L5 — backend) при создании/удалении карточек.
class Deck {
  final int id;
  final String name;
  final String subject;
  final int cardCount;

  const Deck(this.id, this.name, this.subject, [this.cardCount = 0]);

  /// Граница JSON (L5): {"id", "name", "subject", "cardCount"} с сервера.
  factory Deck.fromJson(Map<String, dynamic> j) => Deck(
    j['id'] as int,
    j['name'] as String,
    j['subject'] as String,
    (j['cardCount'] as num?)?.toInt() ?? 0,
  );

  /// Без id и cardCount — идентичность даёт сервер, cardCount он же и считает.
  Map<String, dynamic> toJson() => {'name': name, 'subject': subject};

  /// «Та же колода, другая идентичность или поля».
  Deck copyWith({int? id, String? name, String? subject, int? cardCount}) =>
      Deck(id ?? this.id, name ?? this.name, subject ?? this.subject, cardCount ?? this.cardCount);
}
