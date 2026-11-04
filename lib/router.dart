import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/card_form_screen.dart';
import 'screens/deck_detail_screen.dart';
import 'screens/deck_form_screen.dart';
import 'screens/decks_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/review_session_screen.dart';
import 'screens/stats_screen.dart';
import 'widgets/app_shell.dart';

/// Корневой навигатор: на нём открывается сессия повторения — на весь экран,
/// без нижней панели (как урок в Duolingo).
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Router строится в main(): стартовый адрес зависит от сохранённого token-а (L5).
late final GoRouter router;

/// Router для текущего запуска: вошёл — сразу в колоды, иначе — на login.
GoRouter createRouter({required String initialLocation}) =>
    GoRouter(navigatorKey: rootNavigatorKey, initialLocation: initialLocation, routes: appRoutes);

/// Карта маршрутов L3 — без изменений: login снаружи, три раздела — во вкладках shell-а.
final appRoutes = <RouteBase>[
  GoRoute(
    path: '/login', // ВНЕ shell-а: login без вкладок
    builder: (context, state) => const LoginScreen(),
  ),
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
    branches: [
      // Вкладка 1: колоды и всё, что глубже
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/decks',
            builder: (context, state) => const DecksScreen(),
            routes: [
              GoRoute(
                path: 'new', // /decks/new — ФИКСИРОВАННЫЙ, стоит перед ':id'
                builder: (context, state) => const DeckFormScreen(),
              ),
              GoRoute(
                path: 'review', // /decks/review — все карточки к повторению сегодня
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const ReviewSessionScreen(),
              ),
              GoRoute(
                path: ':id', // /decks/7
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return DeckDetailScreen(id: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit', // /decks/7/edit
                    builder: (context, state) =>
                        DeckFormScreen(deckId: int.parse(state.pathParameters['id']!)),
                  ),
                  GoRoute(
                    path: 'review', // /decks/7/review — сессия по одной колоде
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        ReviewSessionScreen(deckId: int.parse(state.pathParameters['id']!)),
                  ),
                  GoRoute(
                    path: 'cards/new', // /decks/7/cards/new — перед 'cards/:cardId'
                    builder: (context, state) =>
                        CardFormScreen(deckId: int.parse(state.pathParameters['id']!)),
                  ),
                  GoRoute(
                    path: 'cards/:cardId', // /decks/7/cards/42 — редактирование карточки
                    builder: (context, state) => CardFormScreen(
                      deckId: int.parse(state.pathParameters['id']!),
                      cardId: int.parse(state.pathParameters['cardId']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Вкладка 2: статистика
      StatefulShellBranch(
        routes: [GoRoute(path: '/stats', builder: (context, state) => const StatsScreen())],
      ),
      // Вкладка 3: профиль
      StatefulShellBranch(
        routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())],
      ),
    ],
  ),
];
