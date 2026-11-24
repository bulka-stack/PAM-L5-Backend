import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Толстый скруглённый прогресс-бар с бликом — как в уроках Duolingo.
/// Используется в карточке колоды, в сессии повторения и в профиле (цель дня).
class DuoProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color? color;
  final double height;

  const DuoProgressBar({super.key, required this.value, this.color, this.height = 16});

  @override
  Widget build(BuildContext context) {
    final duo = context.duo;
    final fill = color ?? duo.green;
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: duo.border)),
            FractionallySizedBox(
              widthFactor: v,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(height)),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(height / 2, height * 0.22, height / 2, 0),
                    child: Container(
                      height: height * 0.22,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(height),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
