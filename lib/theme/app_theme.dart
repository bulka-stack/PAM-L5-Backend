import 'package:flutter/material.dart';

/// Фирменные акценты в стиле Duolingo, которых нет в стандартной ColorScheme:
/// «объёмная» тень кнопок, оранжевый огонь серии, золотой XP и т. д.
/// Экраны берут их через `context.duo`, а не пишут цвета в коде.
@immutable
class DuoPalette extends ThemeExtension<DuoPalette> {
  const DuoPalette({
    required this.green,
    required this.greenShadow,
    required this.greenLight,
    required this.blue,
    required this.blueShadow,
    required this.blueLight,
    required this.red,
    required this.redShadow,
    required this.redLight,
    required this.orange,
    required this.orangeShadow,
    required this.gold,
    required this.purple,
    required this.border,
    required this.muted,
    required this.text,
    required this.wash,
  });

  final Color green;
  final Color greenShadow;
  final Color greenLight;
  final Color blue;
  final Color blueShadow;
  final Color blueLight;
  final Color red;
  final Color redShadow;
  final Color redLight;
  final Color orange;
  final Color orangeShadow;
  final Color gold;
  final Color purple;
  final Color border;
  final Color muted;
  final Color text;
  final Color wash;

  static const light = DuoPalette(
    green: Color(0xFF58CC02),
    greenShadow: Color(0xFF58A700),
    greenLight: Color(0xFFD7FFB8),
    blue: Color(0xFF1CB0F6),
    blueShadow: Color(0xFF1899D6),
    blueLight: Color(0xFFDDF4FF),
    red: Color(0xFFFF4B4B),
    redShadow: Color(0xFFEA2B2B),
    redLight: Color(0xFFFFDFE0),
    orange: Color(0xFFFF9600),
    orangeShadow: Color(0xFFE08300),
    gold: Color(0xFFFFC800),
    purple: Color(0xFFCE82FF),
    border: Color(0xFFE5E5E5),
    muted: Color(0xFFAFAFAF),
    text: Color(0xFF4B4B4B),
    wash: Color(0xFFF7F7F7),
  );

  @override
  DuoPalette copyWith({Color? green, Color? blue, Color? red, Color? orange}) => DuoPalette(
    green: green ?? this.green,
    greenShadow: greenShadow,
    greenLight: greenLight,
    blue: blue ?? this.blue,
    blueShadow: blueShadow,
    blueLight: blueLight,
    red: red ?? this.red,
    redShadow: redShadow,
    redLight: redLight,
    orange: orange ?? this.orange,
    orangeShadow: orangeShadow,
    gold: gold,
    purple: purple,
    border: border,
    muted: muted,
    text: text,
    wash: wash,
  );

  @override
  DuoPalette lerp(ThemeExtension<DuoPalette>? other, double t) {
    if (other is! DuoPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return DuoPalette(
      green: l(green, other.green),
      greenShadow: l(greenShadow, other.greenShadow),
      greenLight: l(greenLight, other.greenLight),
      blue: l(blue, other.blue),
      blueShadow: l(blueShadow, other.blueShadow),
      blueLight: l(blueLight, other.blueLight),
      red: l(red, other.red),
      redShadow: l(redShadow, other.redShadow),
      redLight: l(redLight, other.redLight),
      orange: l(orange, other.orange),
      orangeShadow: l(orangeShadow, other.orangeShadow),
      gold: l(gold, other.gold),
      purple: l(purple, other.purple),
      border: l(border, other.border),
      muted: l(muted, other.muted),
      text: l(text, other.text),
      wash: l(wash, other.wash),
    );
  }
}

/// `context.duo.orange` вместо `Theme.of(context).extension<DuoPalette>()!.orange`.
extension DuoThemeContext on BuildContext {
  DuoPalette get duo => Theme.of(this).extension<DuoPalette>()!;
}

/// Seed-цвет домена: «учебный» зелёный Duolingo — цвет успеха и прогресса.
const Color studySeed = Color(0xFF58CC02);

ThemeData buildAppTheme() {
  const duo = DuoPalette.light;

  // ColorScheme выводится из seed-цвета; fidelity сохраняет яркость seed-а.
  // Поверх — фирменные роли: белый фон, синий secondary, красный error.
  final scheme =
      ColorScheme.fromSeed(
        seedColor: studySeed,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ).copyWith(
        primary: duo.green,
        onPrimary: Colors.white,
        primaryContainer: duo.greenLight,
        onPrimaryContainer: duo.greenShadow,
        secondary: duo.blue,
        onSecondary: Colors.white,
        secondaryContainer: duo.blueLight,
        onSecondaryContainer: duo.blueShadow,
        tertiary: duo.orange,
        onTertiary: Colors.white,
        error: duo.red,
        onError: Colors.white,
        errorContainer: duo.redLight,
        surface: Colors.white,
        onSurface: duo.text,
        onSurfaceVariant: const Color(0xFF777777),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: duo.wash,
        surfaceContainer: duo.wash,
        surfaceContainerHighest: duo.border,
        outline: duo.muted,
        outlineVariant: duo.border,
      );

  final base = ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: 'Nunito');

  final rounded16 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  OutlineInputBorder field(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: c, width: 2),
  );

  return base.copyWith(
    scaffoldBackgroundColor: Colors.white,
    extensions: const [duo],
    textTheme: base.textTheme
        .copyWith(
          headlineLarge: const TextStyle(fontWeight: FontWeight.w900),
          headlineMedium: const TextStyle(fontWeight: FontWeight.w900),
          headlineSmall: const TextStyle(fontWeight: FontWeight.w900),
          titleLarge: const TextStyle(fontWeight: FontWeight.w800),
          titleMedium: const TextStyle(fontWeight: FontWeight.w800),
          titleSmall: const TextStyle(fontWeight: FontWeight.w800),
          bodyLarge: const TextStyle(fontWeight: FontWeight.w600),
          bodyMedium: const TextStyle(fontWeight: FontWeight.w600),
          bodySmall: const TextStyle(fontWeight: FontWeight.w600),
          labelLarge: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8),
          labelMedium: const TextStyle(fontWeight: FontWeight.w800),
          labelSmall: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.6),
        )
        .apply(bodyColor: duo.text, displayColor: duo.text, fontFamily: 'Nunito'),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: duo.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: duo.text,
      ),
      shape: Border(bottom: BorderSide(color: duo.border, width: 2)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: duo.border, width: 2),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: duo.wash,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: duo.muted, fontWeight: FontWeight.w700),
      labelStyle: TextStyle(color: duo.muted, fontWeight: FontWeight.w700),
      border: field(duo.border),
      enabledBorder: field(duo.border),
      focusedBorder: field(duo.blue),
      errorBorder: field(duo.red),
      focusedErrorBorder: field(duo.red),
      errorStyle: TextStyle(color: duo.red, fontWeight: FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: rounded16,
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: duo.blue,
        textStyle: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: duo.blue,
      foregroundColor: Colors.white,
      elevation: 0,
      highlightElevation: 0,
      shape: rounded16,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: duo.blueLight,
      side: BorderSide(color: duo.border, width: 2),
      shape: rounded16,
      labelStyle: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: duo.text),
      showCheckmark: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: duo.blueLight,
      indicatorShape: rounded16,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: duo.text),
      ),
    ),
    dividerTheme: DividerThemeData(color: duo.border, thickness: 2),
    listTileTheme: ListTileThemeData(
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: duo.text,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: duo.muted,
      ),
      iconColor: duo.muted,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? duo.blue : duo.border,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: duo.text,
      contentTextStyle: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700),
      shape: rounded16,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: duo.text,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: duo.green,
      linearTrackColor: duo.border,
    ),
  );
}
