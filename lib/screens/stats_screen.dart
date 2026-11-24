import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/library_model.dart';
import '../models/sessions_model.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/section_title.dart';
import '../widgets/session_tile.dart';
import '../widgets/stat_tile.dart';
import '../widgets/week_activity_chart.dart';

/// Экран 7. Статистика: история сессий и процент правильных ответов.
/// L4: всё считается в SessionsModel; три состояния; удаление сессии — свайпом.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<SessionsModel>();
    final library = context.watch<LibraryModel>();

    final Widget body;
    if (stats.isLoading && stats.sessions.isEmpty) {
      body = const LoadingView();
    } else if (stats.error != null) {
      body = ErrorView(
        message: stats.error!,
        onRetry: () {
          // имена колод для истории берутся из LibraryModel — перезагружаем обе модели
          context.read<SessionsModel>().load();
          context.read<LibraryModel>().load();
        },
      );
    } else {
      body = _content(context, stats, library);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: body,
    );
  }

  Widget _content(BuildContext context, SessionsModel stats, LibraryModel library) {
    final duo = context.duo;
    final sessions = stats.sessions;
    return RefreshIndicator(
      onRefresh: () => context.read<SessionsModel>().load(),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.3,
                    children: [
                      StatTile(
                        icon: Icons.check_circle_rounded,
                        color: duo.green,
                        value: '${stats.accuracy}%',
                        label: 'точность',
                      ),
                      StatTile(
                        icon: Icons.local_fire_department_rounded,
                        color: duo.orange,
                        value: daysLabel(stats.streakDays),
                        label: 'серия',
                      ),
                      StatTile(
                        icon: Icons.style_rounded,
                        color: duo.blue,
                        value: '${stats.totalReviewed}',
                        label: 'повторено',
                      ),
                      StatTile(
                        icon: Icons.timer_rounded,
                        color: duo.purple,
                        value: '${sessions.length}',
                        label: 'сессий',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SectionTitle('Активность за неделю'),
                  WeekActivityChart(values: stats.weekActivity, labels: stats.weekLabels),
                  const SizedBox(height: 8),
                  const SectionTitle('История сессий'),
                  if (sessions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Сессий пока нет — начните повторение',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: duo.muted),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = sessions[i];
                return Dismissible(
                  key: ValueKey(s.id), // идентичность из данных
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: duo.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.delete_rounded, color: Theme.of(context).colorScheme.onError),
                  ),
                  confirmDismiss: (_) async {
                    final messenger = ScaffoldMessenger.of(context);
                    final error = await context.read<SessionsModel>().remove(s.id);
                    messenger.showSnackBar(
                      SnackBar(content: Text(error ?? 'Сессия удалена из истории')),
                    );
                    return false; // из списка её уже убрала модель
                  },
                  child: SessionTile(
                    session: s,
                    deckName: deckTitle(library, s.deckId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
