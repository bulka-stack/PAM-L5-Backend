import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/deck.dart';
import '../models/library_model.dart';
import '../models/sessions_model.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/subjects.dart';
import '../widgets/deck_card.dart';
import '../widgets/duo_button.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/streak_chip.dart';

/// Экран 2. Мои колоды: поиск + число карточек к повторению сегодня.
/// L4: данные — из LibraryModel (watch в build), три состояния: грузится / данные / ошибка.
class DecksScreen extends StatefulWidget {
  const DecksScreen({super.key});

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  // Эфемерное состояние экрана: текст поиска и выбранная дисциплина → setState.
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _subject;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Deck> _visible(List<Deck> decks) {
    final q = _query.trim().toLowerCase();
    return decks
        .where((d) => _subject == null || d.subject == _subject)
        .where((d) => q.isEmpty || d.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final duo = context.duo;
    final library = context.watch<LibraryModel>(); // ПОКАЗЫВАЮ и слежу — watch в build
    final stats = context.watch<SessionsModel>();

    final Widget body;
    if (library.isLoading && library.decks.isEmpty) {
      body = const LoadingView(); // 1) грузится
    } else if (library.error != null) {
      body = ErrorView(
        message: library.error!, // 2) упало
        onRetry: () => context.read<LibraryModel>().load(), // read: действие
      );
    } else {
      body = _buildList(context, library); // 3) данные
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Мои колоды'),
        actions: [
          StreakChip(
            icon: Icons.local_fire_department_rounded,
            color: duo.orange,
            value: '${stats.streakDays}',
          ),
          StreakChip(icon: Icons.bolt_rounded, color: duo.gold, value: '${stats.xp}'),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/decks/new'),
        tooltip: 'Новая колода',
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      body: body,
    );
  }

  Widget _buildList(BuildContext context, LibraryModel library) {
    final duo = context.duo;
    final text = Theme.of(context).textTheme;
    final dueTotal = library.totalDue;
    final decks = _visible(library.decks);

    return RefreshIndicator(
      onRefresh: () => context.read<LibraryModel>().load(),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: duo.green, width: 2),
                    ),
                    color: duo.greenLight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Сегодня к повторению',
                            style: text.titleMedium?.copyWith(color: duo.greenShadow),
                          ),
                          Text(
                            cardsLabel(dueTotal),
                            style: text.headlineMedium?.copyWith(color: duo.greenShadow),
                          ),
                          const SizedBox(height: 12),
                          DuoButton(
                            label: dueTotal == 0 ? 'Всё повторено' : 'Начать повторение',
                            icon: Icons.play_arrow_rounded,
                            onPressed: dueTotal == 0 ? null : () => context.push('/decks/review'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Поиск колоды',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Очистить',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => setState(() {
                                _searchCtrl.clear();
                                _query = '';
                              }),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: subjects.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final subject = i == 0 ? null : subjects[i - 1];
                        return ChoiceChip(
                          label: Text(subject ?? 'Все'),
                          selected: _subject == subject,
                          onSelected: (_) => setState(() => _subject = subject),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (decks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  library.decks.isEmpty ? 'Колод пока нет — создайте первую' : 'Ничего не найдено',
                  style: text.titleMedium?.copyWith(color: duo.muted),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              sliver: SliverList.separated(
                itemCount: decks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final deck = decks[index];
                  return DeckCard(
                    key: ValueKey(deck.id), // идентичность из данных
                    deck: deck,
                    cardCount: library.cardCount(deck.id),
                    dueCount: library.dueCount(deck.id),
                    learnedCount: library.learnedCount(deck.id),
                    onTap: () => context.push('/decks/${deck.id}'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
