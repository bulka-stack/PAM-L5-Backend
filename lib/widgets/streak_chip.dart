import 'package:flutter/material.dart';

/// Счётчик в AppBar: иконка + число (серия дней 🔥, XP ⚡, к повторению).
/// Используется на экранах «Мои колоды» и «Профиль».
class StreakChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;

  const StreakChip({super.key, required this.icon, required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 2),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}
