import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/api_client.dart';
import 'data/auth_api.dart';
import 'data/http_card_repository.dart';
import 'data/http_deck_repository.dart';
import 'data/http_session_repository.dart';
import 'data/http_user_repository.dart';
import 'data/token_store.dart';
import 'models/library_model.dart';
import 'models/sessions_model.dart';
import 'models/user_model.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Адрес backend-а. Эмулятор Android не знает «localhost» — сервер на ноутбуке это 10.0.2.2;
/// на desktop/web — localhost; для телефона: `flutter run --dart-define=API_BASE=http://<IP>:8080`
String get apiBase {
  const override = String.fromEnvironment('API_BASE');
  if (override.isNotEmpty) return override;
  final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  return android ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
}

/// Корень композиции: ЗДЕСЬ (и только здесь) меняется источник данных.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // prefs до runApp (C9)
  final tokens = TokenStore();
  final loggedIn = await tokens.read() != null; // запуск решает по token-у

  router = createRouter(initialLocation: loggedIn ? '/decks' : '/login');

  final api = ApiClient(
    apiBase,
    tokens,
    onUnauthorized: () => router.go('/login'), // 401 → login, в одном месте
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthApi>(create: (_) => AuthApi(apiBase, tokens)),
        ChangeNotifierProvider(
          create: (_) => LibraryModel(HttpDeckRepository(api), HttpCardRepository(api))..load(),
        ),
        ChangeNotifierProvider(create: (_) => SessionsModel(HttpSessionRepository(api))..load()),
        ChangeNotifierProvider(create: (_) => UserModel(HttpUserRepository(api))..load()),
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
