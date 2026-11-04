import 'package:flutter/material.dart';

import '../data/flashcard.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Строка карточки в списке колоды: лицевая сторона, ответ, дата повторения и ease.
/// Используется на экране колоды и в итогах сессии.
class FlashcardTile extends StatelessWidget {
  final Flashcard card;

  /// Момент, относительно которого карточка «к повторению».
  final DateTime now;
  final VoidCallback? onTap; // L3: открыть форму редактирования карточки

  const FlashcardTile({super.key, required this.card, required this.now, this.onTap});

  @override
  Widget build(BuildContext context) {
    final duo = context.duo;
    final text = Theme.of(context).textTheme;
    final due = card.isDue(now);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.front, style: text.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      card.back,
                      style: text.bodyMedium?.copyWith(color: duo.muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: due ? duo.redLight : duo.blueLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      due ? 'сегодня' : formatShortDate(card.nextReviewAt),
                      style: text.labelMedium?.copyWith(
                        color: due ? duo.redShadow : duo.blueShadow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ease ${card.easeFactor.toStringAsFixed(2)}',
                    style: text.bodySmall?.copyWith(color: duo.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
