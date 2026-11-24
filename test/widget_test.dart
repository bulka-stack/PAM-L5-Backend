// Дымовой тест L5: приложение стартует на /login (token-а нет), форма валидирует локально.
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_cards/data/api_client.dart';
import 'package:study_cards/data/auth_api.dart';
import 'package:study_cards/data/http_card_repository.dart';
import 'package:study_cards/data/http_deck_repository.dart';
import 'package:study_cards/data/http_session_repository.dart';
import 'package:study_cards/data/http_user_repository.dart';
import 'package:study_cards/data/token_store.dart';
import 'package:study_cards/main.dart';
import 'package:study_cards/models/library_model.dart';
import 'package:study_cards/models/sessions_model.dart';
import 'package:study_cards/models/user_model.dart';
import 'package:study_cards/router.dart';

void main() {
  testWidgets('старт на /login; регистрация показывает поле «Имя»', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final tokens = TokenStore();
    final api = ApiClient('http://localhost:8080', tokens);
    router = createRouter(initialLocation: '/login');
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => AuthApi('http://localhost:8080', tokens)),
          ChangeNotifierProvider(
            create: (_) => LibraryModel(HttpDeckRepository(api), HttpCardRepository(api)),
          ),
          ChangeNotifierProvider(create: (_) => SessionsModel(HttpSessionRepository(api))),
          ChangeNotifierProvider(create: (_) => UserModel(HttpUserRepository(api))),
        ],
        child: const StudyCardsApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ВОЙТИ'));
    await tester.pump();
    expect(find.text('Введите e-mail'), findsOneWidget);

    await tester.tap(find.text('Нет аккаунта? Зарегистрируйтесь'));
    await tester.pump();
    expect(find.text('СОЗДАТЬ АККАУНТ'), findsOneWidget);
    expect(find.text('Имя'), findsOneWidget);
  });
}
