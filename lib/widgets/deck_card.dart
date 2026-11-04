import 'package:flutter/material.dart';

import '../data/deck.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'duo_progress_bar.dart';
import 'subject_avatar.dart';

/// Карточка колоды в списке: дисциплина, название, число карточек,
/// сколько повторить сегодня и прогресс изучения.
/// Используется на экранах «Мои колоды» и «Профиль».
class DeckCard extends StatelessWidget {
  final Deck deck;
  final int cardCount; // L4: счётчики считает модель, карточка их только показывает
  final int dueCount;
  final int learnedCount;
  final VoidCallback? onTap; // L3: карточка «оживает» — переход к деталям

  const DeckCard({
    super.key,
    required this.deck,
    required this.cardCount,
    required this.dueCount,
    required this.learnedCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final duo = context.duo;
    final text = Theme.of(context).textTheme;
    final progress = cardCount == 0 ? 0.0 : learnedCount / cardCount;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SubjectAvatar(subject: deck.subject),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      style: text.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${deck.subject} · ${cardsLabel(cardCount)}',
                      style: text.bodySmall?.copyWith(color: duo.muted),
                    ),
                    const SizedBox(height: 8),
                    DuoProgressBar(value: progress, height: 12),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _DueBadge(count: dueCount),
            ],
          ),
        ),
      ),
    );
  }
}

/// Значок «к повторению сегодня»: оранжевый, если есть что повторять.
class _DueBadge extends StatelessWidget {
  final int count;
  const _DueBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final duo = context.duo;
    final active = count > 0;
    return Column(
      children: [
        Icon(
          active ? Icons.bolt_rounded : Icons.check_circle_rounded,
          color: active ? duo.orange : duo.green,
          size: 26,
        ),
        Text(
          active ? '$count' : 'всё',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: active ? duo.orange : duo.green),
        ),
      ],
    );
  }
}
