import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'duo_button.dart';

/// Состояние «ошибка»: сообщение из Err + кнопка «Повторить».
/// Ошибка никогда не молчит и всегда имеет retry. Используется на всех экранах с данными.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final duo = context.duo;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.cloud_off_rounded, size: 88, color: duo.red),
            const SizedBox(height: 16),
            Text('Что-то пошло не так', textAlign: TextAlign.center, style: text.headlineSmall),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: duo.muted),
            ),
            const SizedBox(height: 24),
            DuoButton(label: 'Повторить', icon: Icons.refresh_rounded, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
