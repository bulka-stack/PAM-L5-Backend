import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/mock_card_repository.dart';
import 'data/mock_database.dart';
import 'data/mock_deck_repository.dart';
import 'data/mock_session_repository.dart';
import 'data/mock_user_repository.dart';
import 'models/library_model.dart';
import 'models/sessions_model.dart';
import 'models/user_model.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Корень композиции: ЗДЕСЬ (и только здесь) выбирается источник данных.
void main() {
  final db = MockDatabase(); // на L5: http-реализации — и всё
  final decks = MockDeckRepository(db);
  final cards = MockCardRepository(db);
  final sessions = MockSessionRepository(db);
  final users = MockUserRepository(db);

  runApp(
    MultiProvider(
      providers: [
        // леса демонстрации аварии (переключатель в профиле) — исчезают на L5
        Provider<MockDatabase>.value(value: db),
        ChangeNotifierProvider(create: (_) => LibraryModel(decks, cards)..load()), // DI + старт
        ChangeNotifierProvider(create: (_) => SessionsModel(sessions)..load()),
        ChangeNotifierProvider(create: (_) => UserModel(users)..load()),
      ],
      child: const StudyCardsApp(), // MaterialApp.router — нетронут с L3
    ),
  );
}

class StudyCardsApp extends StatelessWidget {
  const StudyCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StudyCards',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
