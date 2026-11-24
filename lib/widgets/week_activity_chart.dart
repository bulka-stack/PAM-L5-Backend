import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Столбчатая диаграмма «карточек за день» за неделю — без сторонних пакетов.
class WeekActivityChart extends StatelessWidget {
  final List<int> values; // 7 значений, последнее — сегодня
  final List<String> labels; // подписи дней недели
  final int highlightIndex; // «сегодня»

  const WeekActivityChart({
    super.key,
    required this.values,
    required this.labels,
    this.highlightIndex = 6,
  });

  @override
  Widget build(BuildContext context) {
    final duo = context.duo;
    final text = Theme.of(context).textTheme;
    final maxValue = values.fold<int>(1, (m, v) => v > m ? v : m);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${values[i]}', style: text.labelSmall?.copyWith(color: duo.muted)),
                      const SizedBox(height: 4),
                      Container(
                        width: 22,
                        height: 100 * values[i] / maxValue + 4,
                        decoration: BoxDecoration(
                          color: i == highlightIndex ? duo.orange : duo.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        style: text.labelMedium?.copyWith(
                          color: i == highlightIndex ? duo.orange : duo.muted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
