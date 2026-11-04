import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/mock_database.dart';
import '../models/library_model.dart';
import '../models/sessions_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/duo_button.dart';
import '../widgets/duo_progress_bar.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/section_title.dart';
import '../widgets/session_tile.dart';
import '../widgets/stat_tile.dart';

/// Экран 8. Профиль пользователя.
/// L4: пользователь — из UserModel, статистика — из SessionsModel и LibraryModel.
/// Переключатель «Симулировать сбой сети» — единственное место UI, знающее о mock-е
/// (леса демонстрации, исчезают на L5 вместе с mock-ом).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _simulateError = false; // эфемерное состояние переключателя → setState (C7)

  /// Блокирующее решение → AlertDialog с результатом (C6).
  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Серия дней и прогресс сохранятся.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false), // dialogCtx, не context экрана
            child: const Text('Нет'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Да, выйти'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.go('/login'); // go: раздел с вкладками уходит из стека
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<UserModel>();
    final user = userModel.user;

    final Widget body;
    if (userModel.isLoading && user == null) {
      body = const LoadingView();
    } else if (userModel.error != null) {
      body = ErrorView(message: userModel.error!, onRetry: () => context.read<UserModel>().load());
    } else if (user == null) {
      body = const LoadingView();
    } else {
      body = _content(context, user.name, user.email);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: body,
    );
  }

  Widget _content(BuildContext context, String name, String email) {
    final duo = context.duo;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final stats = context.watch<SessionsModel>();
    final library = context.watch<LibraryModel>();
    final initials = name.split(' ').where((p) => p.isNotEmpty).map((p) => p[0]).take(2).join();
    final lastSession = stats.sessions.firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: duo.blueLight,
            foregroundColor: duo.blueShadow,
            child: Text(initials, style: text.headlineMedium?.copyWith(color: duo.blueShadow)),
          ),
        ),
        const SizedBox(height: 12),
        Text(name, textAlign: TextAlign.center, style: text.headlineSmall),
        Text(
          email,
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: duo.muted),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.3,
          children: [
            StatTile(
              icon: Icons.local_fire_department_rounded,
              color: duo.orange,
              value: '${stats.streakDays}',
              label: 'дней подряд',
            ),
            StatTile(
              icon: Icons.bolt_rounded,
              color: duo.gold,
              value: '${stats.xp}',
              label: 'очков XP',
            ),
            StatTile(
              icon: Icons.layers_rounded,
              color: duo.blue,
              value: '${library.decks.length}',
              label: 'колод',
            ),
            StatTile(
              icon: Icons.style_rounded,
              color: duo.green,
              value: '${library.cards.length}',
              label: 'карточек',
            ),
          ],
        ),
        const SizedBox(height: 8),
        const SectionTitle('Цель на день'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.reviewedToday} из ${cardsLabel(SessionsModel.dailyGoal)}',
                  style: text.titleMedium,
                ),
                const SizedBox(height: 10),
                DuoProgressBar(
                  value: stats.reviewedToday / SessionsModel.dailyGoal,
                  color: duo.orange,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const SectionTitle('Настройки'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                secondary: const Icon(Icons.notifications_rounded),
                title: const Text('Напоминание в 20:00'),
              ),
              const Divider(height: 2),
              ListTile(
                leading: const Icon(Icons.flag_rounded),
                title: const Text('Ежедневная цель'),
                trailing: Text(
                  cardsLabel(SessionsModel.dailyGoal),
                  style: text.titleSmall?.copyWith(color: scheme.secondary),
                ),
              ),
              const Divider(height: 2),
              // Леса демонстрации аварии (Задание 7 L4): умирают на L5 вместе с mock-ом.
              SwitchListTile(
                value: _simulateError,
                onChanged: (value) {
                  setState(() => _simulateError = value);
                  context.read<MockDatabase>().simulateError = value;
                },
                secondary: Icon(Icons.wifi_off_rounded, color: _simulateError ? duo.red : null),
                title: const Text('Симулировать сбой сети'),
                subtitle: const Text('Любой запрос к хранилищу провалится'),
              ),
            ],
          ),
        ),
        if (lastSession != null) ...[
          const SizedBox(height: 8),
          const SectionTitle('Последняя сессия'),
          SessionTile(
            session: lastSession,
            deckName: deckTitle(library, lastSession.deckId),
          ),
        ],
        const SizedBox(height: 24),
        DuoButton(
          label: 'Выйти из аккаунта',
          variant: DuoButtonVariant.outline,
          icon: Icons.logout_rounded,
          onPressed: () => _logout(context),
        ),
      ],
    );
  }
}
