import 'package:flutter/material.dart';
import 'package:my_quran/app/models.dart';

String getArabicNumber(int number) {
  const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return number
      .toString()
      .split('')
      .map((digit) => arabicNumerals[int.parse(digit)])
      .join();
}

extension ColorOpacity on Color {
  Color applyOpacity(double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return withAlpha((255.0 * opacity).round());
  }
}

extension ThemeContext on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  String? get fontFamily => textTheme.bodyLarge?.fontFamily;
  bool get isDarkMode => colorScheme.brightness == Brightness.dark;

  bool get isHafsFontFamily => fontFamily == FontFamily.hafs.name;
  bool get isRustamFontFamily => fontFamily == FontFamily.rustam.name;
}

extension AppThemeX on AppTheme {
  bool get isDark => switch (this) {
    AppTheme.light || AppTheme.classic || AppTheme.sepia => false,
    AppTheme.dark || AppTheme.amoled => true,
  };

  /// For MaterialApp themeMode
  ThemeMode get themeMode => isDark ? ThemeMode.dark : ThemeMode.light;

  /// Quick toggle counterpart
  AppTheme? get toggleCounterpart => switch (this) {
    AppTheme.light => AppTheme.dark,
    AppTheme.dark => AppTheme.light,
    _ => null, // no simple toggle, open picker
  };
}

// ({Color background, Color text, Color secondary}) resolveReadingThemeColors(
//   BuildContext context,
//   ReadingTheme theme,
// ) {
//   return switch (theme) {
//     ReadingTheme.system => (
//       background: Colors.transparent,
//       text: Theme.of(context).colorScheme.onSurface,
//       secondary: Theme.of(context).colorScheme.primary,
//     ),
//     ReadingTheme.classic => (
//       background: const Color(0xFFFFFFFF),
//       text: const Color(0xFF000000),
//       secondary: const Color(0xFF1565C0),
//     ),
//     ReadingTheme.sepia => (
//       background: const Color(0xFFF5E6C8),
//       text: const Color(0xFF5B4636),
//       secondary: const Color(0xFF8D6E4C),
//     ),
//     ReadingTheme.night => (
//       background: const Color(0xFF000000),
//       text: const Color(0xFFE0E0E0),
//       secondary: const Color(0xFF90CAF9),
//     ),
//   };
// }

ReadingColors resolveReadingColors(BuildContext context, AppTheme theme) {
  final colorScheme = Theme.of(context).colorScheme;

  return switch (theme) {
    AppTheme.light => ReadingColors(
      background: colorScheme.surface,
      text: colorScheme.onSurface,
      primary: colorScheme.primary,
      secondary: colorScheme.secondary,
      onSecondary: colorScheme.onSecondary,
      highlight: colorScheme.surfaceContainerHighest,
      surfaceContainer: colorScheme.surfaceContainerHighest,
    ),
    AppTheme.dark => ReadingColors(
      background: colorScheme.surface,
      text: colorScheme.onSurface,
      primary: colorScheme.primary,
      secondary: colorScheme.secondary,
      onSecondary: colorScheme.onSecondary,
      highlight: colorScheme.surfaceContainerHigh,
      surfaceContainer: colorScheme.surfaceContainerHigh,
    ),
    AppTheme.classic => const ReadingColors(
      background: Color(0xFFFFFFFF),
      text: Color(0xFF212121),
      primary: Color(0xFF0D47A1),
      secondary: Color(0xFFBBDEFB),
      onSecondary: Color(0xFF0D47A1),
      highlight: Color(0xFFE3F2FD),
      surfaceContainer: Color(0xFFE8EAF6),
    ),
    AppTheme.amoled => const ReadingColors(
      background: Color(0xFF000000),
      text: Color(0xFFEEEEEE),
      primary: Color(0xFF64B5F6),
      secondary: Color(0xFF1B1B1B),
      onSecondary: Color(0xFFEEEEEE),
      highlight: Color(0xFF212121),
      surfaceContainer: Color(0xFF171717),
    ),
    AppTheme.sepia => const ReadingColors(
      background: Color(0xFFF4E4C1),
      text: Color(0xFF4E3524),
      primary: Color(0xFF795548),
      secondary: Color(0xFFD7C4A0),
      onSecondary: Color(0xFF4E3524),
      highlight: Color(0xFFE6D2AC),
      surfaceContainer: Color(0xFFE0CDAA),
    ),
  };
}
