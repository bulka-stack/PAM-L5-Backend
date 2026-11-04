// Дымовой тест L4: приложение с провайдерами стартует на экране входа.
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:study_cards/data/mock_card_repository.dart';
import 'package:study_cards/data/mock_database.dart';
import 'package:study_cards/data/mock_deck_repository.dart';
import 'package:study_cards/data/mock_session_repository.dart';
import 'package:study_cards/data/mock_user_repository.dart';
import 'package:study_cards/main.dart';
import 'package:study_cards/models/library_model.dart';
import 'package:study_cards/models/sessions_model.dart';
import 'package:study_cards/models/user_model.dart';

void main() {
  testWidgets('старт на /login, пустая форма показывает ошибки', (tester) async {
    final db = MockDatabase();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<MockDatabase>.value(value: db),
          ChangeNotifierProvider(
            create: (_) => LibraryModel(MockDeckRepository(db), MockCardRepository(db))..load(),
          ),
          ChangeNotifierProvider(create: (_) => SessionsModel(MockSessionRepository(db))..load()),
          ChangeNotifierProvider(create: (_) => UserModel(MockUserRepository(db))..load()),
        ],
        child: const StudyCardsApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1)); // mock отвечает через 800 мс
    expect(find.text('StudyCards'), findsOneWidget);

    await tester.tap(find.text('ВОЙТИ'));
    await tester.pump();
    expect(find.text('Введите e-mail'), findsOneWidget);
  });
}
