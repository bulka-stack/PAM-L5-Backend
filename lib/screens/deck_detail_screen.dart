import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/deck.dart';
import '../data/flashcard.dart';
import '../models/library_model.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/duo_button.dart';
import '../widgets/error_view.dart';
import '../widgets/flashcard_tile.dart';
import '../widgets/loading_view.dart';
import '../widgets/section_title.dart';
import '../widgets/stat_tile.dart';
import '../widgets/subject_avatar.dart';

/// Экран 3. Карточка колоды: список карточек + статистика колоды.
/// L4: ищет колоду через модель; удаление — через repository, эффект виден везде.
class DeckDetailScreen extends StatelessWidget {
  final int id;

  const DeckDetailScreen({super.key, required this.id});

  Future<bool> _confirm(BuildContext context, String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Нет')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _deleteDeck(BuildContext context, Deck deck) async {
    final ok = await _confirm(
      context,
      'Удалить колоду?',
      '«${deck.name}» и все её карточки будут удалены.',
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<LibraryModel>().removeDeck(deck.id);
    if (!context.mounted) return; // экран может умереть, пока «запрос» летит
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text('Колода «${deck.name}» удалена')));
    context.pop(); // объекта больше нет — его экран уходит из стека
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryModel>();
    final deck = library.deckById(id);
    if (deck == null) {
      // у null два смысла: список ещё грузится или колоды с таким id нет
      return Scaffold(
        appBar: AppBar(),
        body: library.isLoading
            ? const LoadingView()
            : library.error != null
            ? ErrorView(message: library.error!, onRetry: () => context.read<LibraryModel>().load())
            : const Center(child: Text('Колода не существует')),
      );
    }

    final duo = context.duo;
    final text = Theme.of(context).textTheme;
    final cards = library.cardsOf(id);
    final due = library.dueCount(id);
    final avgEase = cards.isEmpty
        ? 0.0
        : cards.fold<double>(0, (s, c) => s + c.easeFactor) / cards.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Колода'),
        actions: [
          IconButton(
            onPressed: () => context.push('/decks/$id/edit'),
            tooltip: 'Изменить',
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: () => _deleteDeck(context, deck),
            tooltip: 'Удалить',
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/decks/$id/cards/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('КАРТОЧКА'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Row(
            children: [
              SubjectAvatar(subject: deck.subject, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deck.name, style: text.titleLarge),
                    Text(deck.subject, style: text.bodyMedium?.copyWith(color: duo.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: [
              StatTile(
                icon: Icons.style_rounded,
                color: duo.blue,
                value: '${cards.length}',
                label: 'всего карточек',
              ),
              StatTile(
                icon: Icons.bolt_rounded,
                color: duo.orange,
                value: '$due',
                label: 'к повторению',
              ),
              StatTile(
                icon: Icons.emoji_events_rounded,
                color: duo.gold,
                value: '${library.learnedCount(id)}',
                label: 'выучено',
              ),
              StatTile(
                icon: Icons.speed_rounded,
                color: duo.purple,
                value: avgEase.toStringAsFixed(2),
                label: 'средний ease',
              ),
            ],
          ),
          const SizedBox(height: 16),
          DuoButton(
            label: due == 0
                ? 'Всё повторено'
                : 'Повторить $due ${plural(due, 'карточку', 'карточки', 'карточек')}',
            icon: Icons.play_arrow_rounded,
            onPressed: due == 0 ? null : () => context.push('/decks/$id/review'),
          ),
          const SizedBox(height: 16),
          SectionTitle('Карточки (${cards.length})'),
          if (cards.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'В колоде пока нет карточек',
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(color: duo.muted),
              ),
            ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _dismissibleCard(context, cards[i], library.now),
          ),
        ],
      ),
    );
  }

  /// Свайп влево удаляет карточку (с подтверждением). Ключ — из данных, не UniqueKey.
  Widget _dismissibleCard(BuildContext context, Flashcard card, DateTime now) {
    final duo = context.duo;
    return Dismissible(
      key: ValueKey(card.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: duo.red, borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.delete_rounded, color: Theme.of(context).colorScheme.onError),
      ),
      confirmDismiss: (_) async {
        final ok = await _confirm(
          context,
          'Удалить карточку?',
          '«${card.front}» исчезнет из колоды.',
        );
        if (!ok || !context.mounted) return false;
        final messenger = ScaffoldMessenger.of(context);
        final error = await context.read<LibraryModel>().removeCard(card.id);
        messenger.showSnackBar(SnackBar(content: Text(error ?? 'Карточка удалена')));
        // Карточку из списка уже убрала модель (notifyListeners) — сам Dismissible не «досвайпываем».
        return false;
      },
      child: FlashcardTile(
        card: card,
        now: now,
        onTap: () => context.push('/decks/$id/cards/${card.id}'),
      ),
    );
  }
}
