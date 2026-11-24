import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Цветная «плитка» дисциплины с иконкой — вместо обложки колоды.
/// Используется в списке колод, на экране колоды, в форме колоды и в истории сессий.
class SubjectAvatar extends StatelessWidget {
  final String subject;
  final double size;

  const SubjectAvatar({super.key, required this.subject, this.size = 52});

  static IconData iconFor(String subject) => switch (subject) {
    'Языки' => Icons.translate_rounded,
    'Математика' => Icons.functions_rounded,
    'Программирование' => Icons.code_rounded,
    'Естественные науки' => Icons.science_rounded,
    'История' => Icons.account_balance_rounded,
    'Экономика' => Icons.trending_up_rounded,
    _ => Icons.style_rounded,
  };

  static Color colorFor(BuildContext context, String subject) {
    final duo = context.duo;
    return switch (subject) {
      'Языки' => duo.blue,
      'Математика' => duo.purple,
      'Программирование' => duo.green,
      'Естественные науки' => duo.orange,
      'История' => duo.red,
      'Экономика' => duo.gold,
      _ => duo.muted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(context, subject);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border(
          bottom: BorderSide(color: Color.lerp(color, scheme.shadow, 0.18)!, width: 4),
        ),
      ),
      child: Icon(iconFor(subject), color: scheme.onPrimary, size: size * 0.52),
    );
  }
}
