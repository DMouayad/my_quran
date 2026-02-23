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
    AppTheme.classic || AppTheme.sepia => false,
    AppTheme.amoled => true,

    AppTheme.dynamic || AppTheme.myQuran => false, // handled at build time
  };

  /// myQuran and dynamic follow system brightness
  ThemeMode get themeMode => switch (this) {
    AppTheme.myQuran || AppTheme.dynamic => ThemeMode.system,
    AppTheme.classic || AppTheme.sepia => ThemeMode.light,
    AppTheme.amoled => ThemeMode.dark,
  };

  bool get supportsThemeModeToggle =>
      this == AppTheme.myQuran || this == AppTheme.dynamic;
}

({Color bg, Color text}) previewColorsForTheme(
  BuildContext context,
  AppTheme theme,
) {
  return switch (theme) {
    AppTheme.myQuran =>
      context.isDarkMode
          ? (bg: const Color(0xFF0e1514), text: const Color(0xFFdde4e2))
          : (bg: const Color(0xFFf4fbf8), text: const Color(0xFF161d1c)),
    AppTheme.classic => (
      bg: const Color(0xFFFFFFFF),
      text: const Color(0xFF000000),
    ),
    AppTheme.amoled => (
      bg: const Color(0xFF000000),
      text: const Color(0xFFEEEEEE),
    ),
    AppTheme.sepia => (
      bg: const Color(0xFFF4E4C1),
      text: const Color(0xFF4E3524),
    ),
    AppTheme.dynamic => (
      bg: context.colorScheme.surface,
      text: context.colorScheme.onSurface,
    ),
  };
}

extension HexColor on Color {
  /// Converts this [Color] to a hexadecimal string in format #RRGGBB.
  /// Set `withAlpha` to `true` to include the alpha channel.
  String toHex({bool withAlpha = false, bool leadingHashSign = true}) {
    final int argb32 = toARGB32();
    final String hex =
        (withAlpha
            ? (argb32 >> 24 & 0xFF).toRadixString(16).padLeft(2, '0')
            : '') +
        (argb32 >> 16 & 0xFF).toRadixString(16).padLeft(2, '0') +
        (argb32 >> 8 & 0xFF).toRadixString(16).padLeft(2, '0') +
        (argb32 & 0xFF).toRadixString(16).padLeft(2, '0');

    return '${leadingHashSign ? '#' : ''}$hex';
  }
}
