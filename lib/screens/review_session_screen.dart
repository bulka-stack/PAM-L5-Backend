import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/flashcard.dart';
import '../data/review_session.dart';
import '../models/library_model.dart';
import '../models/sessions_model.dart';
import '../models/srs.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/duo_button.dart';
import '../widgets/duo_progress_bar.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/stat_tile.dart';

/// Экран 6. Сессия повторения: переворот карточки + оценка «снова / хорошо / легко».
/// L4: оценка идёт в LibraryModel.review → правило SRS планирует nextReviewAt,
/// repository сохраняет расписание; итог сессии пишется в SessionsModel.
class ReviewSessionScreen extends StatefulWidget {
  /// null — все колоды (кнопка «Начать повторение» на экране колод).
  final int? deckId;

  const ReviewSessionScreen({super.key, this.deckId});

  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends State<ReviewSessionScreen> {
  // Ход сессии — эфемерное состояние экрана: очередь фиксируется в начале.
  List<Flashcard>? _queue;
  int _index = 0;
  bool _flipped = false;
  bool _busy = false;
  bool _saved = false;
  final Map<int, (int reviewed, int correct)> _perDeck = {};

  int get _reviewed => _perDeck.values.fold(0, (s, e) => s + e.$1);
  int get _correct => _perDeck.values.fold(0, (s, e) => s + e.$2);
  bool get _finished => _queue != null && _index >= _queue!.length;

  Future<void> _grade(Grade grade) async {
    final card = _queue![_index];
    setState(() => _busy = true);
    final error = await context.read<LibraryModel>().review(card, grade); // read: действие
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return; // карточка остаётся на экране — можно оценить ещё раз
    }
    final (r, c) = _perDeck[card.deckId] ?? (0, 0);
    _perDeck[card.deckId] = (r + 1, c + (grade == Grade.again ? 0 : 1));
    setState(() {
      _index++;
      _flipped = false;
    });
    if (_finished) await _saveSessions();
  }

  /// Одна ReviewSession на каждую колоду, карточки которой были в сессии.
  Future<void> _saveSessions() async {
    final sessions = context.read<SessionsModel>();
    final now = context.read<LibraryModel>().now;
    for (final MapEntry(key: deckId, value: (reviewed, correct)) in _perDeck.entries) {
      final error = await sessions.add(ReviewSession(0, deckId, now, reviewed, correct));
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        return;
      }
    }
    if (mounted) setState(() => _saved = true);
  }

  Future<void> _close() async {
    if (_index == 0 || _finished) {
      context.pop();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Завершить сессию?'),
        content: Text(
          'Повторено ${cardsLabel(_index)} из ${_queue!.length}. '
          'Расписание уже сохранено.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Продолжить'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _saveSessions(); // прерванная сессия тоже попадает в историю
    if (mounted) context.pop();
  }

  void _finish() {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Сессия завершена: $_correct из $_reviewed верно')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryModel>();
    final duo = context.duo;
    final text = Theme.of(context).textTheme;

    // Очередь фиксируется, как только данные загружены (дальнейшие оценки её не меняют).
    if (_queue == null && !library.isLoading && library.error == null) {
      _queue = library.dueCards(deckId: widget.deckId);
    }
    final queue = _queue;

    final deckName = widget.deckId == null
        ? 'Все колоды'
        : library.deckById(widget.deckId!)?.name ?? '';

    final Widget content;
    if (queue == null) {
      content = library.error != null
          ? ErrorView(message: library.error!, onRetry: () => context.read<LibraryModel>().load())
          : const LoadingView();
    } else if (queue.isEmpty) {
      content = _EmptyState(onBack: () => context.pop());
    } else if (_finished) {
      content = _Summary(
        total: _reviewed,
        correct: _correct,
        xp: _reviewed * SessionsModel.xpPerCard,
        onDone: _saved ? _finish : null,
      );
    } else {
      content = _CardFace(
        card: queue[_index],
        flipped: _flipped,
        onFlip: () => setState(() => _flipped = true),
      );
    }

    final total = queue?.length ?? 0;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Закрыть',
                    onPressed: _close,
                    icon: Icon(Icons.close_rounded, color: duo.muted, size: 30),
                  ),
                  Expanded(child: DuoProgressBar(value: total == 0 ? 0 : _index / total)),
                  const SizedBox(width: 12),
                  Text(
                    '${_index.clamp(0, total)}/$total',
                    style: text.titleMedium?.copyWith(color: duo.muted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(deckName, style: text.titleMedium?.copyWith(color: duo.muted)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(padding: const EdgeInsets.only(left: 8), child: content),
              ),
              if (queue != null && queue.isNotEmpty && !_finished) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _flipped
                      ? _GradeButtons(card: queue[_index], busy: _busy, onGrade: _grade)
                      : DuoButton(
                          label: 'Показать ответ',
                          variant: DuoButtonVariant.secondary,
                          onPressed: () => setState(() => _flipped = true),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Три оценки; под каждой — интервал, который назначит правило SRS.
class _GradeButtons extends StatelessWidget {
  final Flashcard card;
  final bool busy;
  final ValueChanged<Grade> onGrade;

  const _GradeButtons({required this.card, required this.busy, required this.onGrade});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    String caption(Grade g) => daysLabel(Srs.nextInterval(card, g));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Насколько легко вы вспомнили ответ?',
          textAlign: TextAlign.center,
          style: text.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DuoButton(
                label: 'Снова',
                caption: caption(Grade.again),
                variant: DuoButtonVariant.danger,
                onPressed: busy ? null : () => onGrade(Grade.again),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DuoButton(
                label: 'Хорошо',
                caption: caption(Grade.good),
                onPressed: busy ? null : () => onGrade(Grade.good),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DuoButton(
                label: 'Легко',
                caption: caption(Grade.easy),
                variant: DuoButtonVariant.secondary,
                onPressed: busy ? null : () => onGrade(Grade.easy),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Карточка: лицевая сторона, после переворота — ещё и ответ.
class _CardFace extends StatelessWidget {
  final Flashcard card;
  final bool flipped;
  final VoidCallback onFlip;

  const _CardFace({required this.card, required this.flipped, required this.onFlip});

  @override
  Widget build(BuildContext context) {
    final duo = context.duo;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: flipped ? null : onFlip,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: DecoratedBox(
          key: ValueKey('${card.id}-$flipped'),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: flipped ? duo.green : duo.border, width: 2),
          ),
          child: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('ВОПРОС', style: text.labelLarge?.copyWith(color: duo.muted)),
                  const SizedBox(height: 8),
                  Text(card.front, textAlign: TextAlign.center, style: text.headlineMedium),
                  if (flipped) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),
                    Text('ОТВЕТ', style: text.labelLarge?.copyWith(color: duo.green)),
                    const SizedBox(height: 8),
                    Text(card.back, textAlign: TextAlign.center, style: text.titleLarge),
                  ] else ...[
                    const SizedBox(height: 24),
                    Text(
                      'нажмите, чтобы перевернуть',
                      style: text.bodySmall?.copyWith(color: duo.muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Итог сессии — «урок пройден».
class _Summary extends StatelessWidget {
  final int total;
  final int correct;
  final int xp;
  final VoidCallback? onDone; // null, пока сессия сохраняется

  const _Summary({
    required this.total,
    required this.correct,
    required this.xp,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final duo = context.duo;
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.emoji_events_rounded, size: 96, color: duo.gold),
        const SizedBox(height: 12),
        Text(
          'Сессия завершена!',
          textAlign: TextAlign.center,
          style: text.headlineMedium?.copyWith(color: duo.gold),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: StatTile(
                icon: Icons.style_rounded,
                color: duo.blue,
                value: '$total',
                label: 'повторено',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.check_circle_rounded,
                color: duo.green,
                value: '${percent(correct, total)}%',
                label: 'точность',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StatTile(icon: Icons.bolt_rounded, color: duo.gold, value: '+$xp XP', label: 'опыт'),
        const SizedBox(height: 24),
        DuoButton(label: onDone == null ? 'Сохранение…' : 'Продолжить', onPressed: onDone),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onBack;
  const _EmptyState({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final duo = context.duo;
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle_rounded, size: 96, color: duo.green),
        const SizedBox(height: 12),
        Text('На сегодня всё повторено!', textAlign: TextAlign.center, style: text.headlineSmall),
        const SizedBox(height: 24),
        DuoButton(label: 'Назад', onPressed: onBack),
      ],
    );
  }
}
