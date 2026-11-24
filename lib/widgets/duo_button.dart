import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum DuoButtonVariant { primary, secondary, danger, outline }

/// «Объёмная» кнопка в стиле Duolingo: FilledButton на тёмной подложке-тени.
/// Используется на экранах входа, колод, колоды, форм, сессии и профиля.
class DuoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final DuoButtonVariant variant;
  final IconData? icon;

  /// Вторая строка мелким шрифтом (например, интервал «3 дн.» под «ХОРОШО»).
  final String? caption;

  const DuoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = DuoButtonVariant.primary,
    this.icon,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final duo = context.duo;
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;

    final (Color face, Color shadow, Color ink) = switch (variant) {
      _ when !enabled => (duo.border, duo.muted.withValues(alpha: 0.5), duo.muted),
      DuoButtonVariant.primary => (scheme.primary, duo.greenShadow, scheme.onPrimary),
      DuoButtonVariant.secondary => (scheme.secondary, duo.blueShadow, scheme.onSecondary),
      DuoButtonVariant.danger => (scheme.error, duo.redShadow, scheme.onError),
      DuoButtonVariant.outline => (scheme.surface, duo.border, scheme.secondary),
    };

    final text = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), textAlign: TextAlign.center),
        if (caption != null)
          Text(
            caption!,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0),
          ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(color: shadow, borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: face,
            foregroundColor: ink,
            disabledBackgroundColor: face,
            disabledForegroundColor: ink,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            side: variant == DuoButtonVariant.outline
                ? BorderSide(color: duo.border, width: 2)
                : BorderSide.none,
          ),
          child: icon == null
              ? text
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 22),
                    const SizedBox(width: 8),
                    Flexible(child: text),
                  ],
                ),
        ),
      ),
    );
  }
}
