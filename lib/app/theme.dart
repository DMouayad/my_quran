import 'package:flutter/material.dart';
import 'package:my_quran/app/models.dart';

const _seedColor = Color(0xFF0F766E);

ThemeData buildThemeForAppTheme(AppTheme appTheme) {
  return switch (appTheme) {
    AppTheme.light => _buildLight(),
    AppTheme.dark => _buildDark(),
    AppTheme.classic => _buildClassic(),
    AppTheme.amoled => _buildAmoled(),
    AppTheme.sepia => _buildSepia(),
  };
}

ThemeData _buildLight() {
  final colorScheme = ColorScheme.fromSeed(seedColor: _seedColor);
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
  );
}

ThemeData _buildDark() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
  );
}

ThemeData _buildClassic() {
  const colorScheme = ColorScheme.light(
    primary: Color(0xFF0D47A1),
    primaryContainer: Color(0xFFBBDEFB),
    onPrimaryContainer: Color(0xFF0D47A1),
    secondary: Color(0xFF1565C0),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE3F2FD),
    onSecondaryContainer: Color(0xFF0D47A1),
    tertiary: Color(0xFF0277BD),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFB3E5FC),
    onTertiaryContainer: Color(0xFF01579B),
    errorContainer: Color(0xFFFCE4EC),
    onErrorContainer: Color(0xFFB00020),
    outline: Color(0xFFBDBDBD),
    outlineVariant: Color(0xFFE0E0E0),
    surfaceContainerHighest: Color(0xFFECEFF1),
    surfaceContainerHigh: Color(0xFFF0F4F8),
    surfaceContainer: Color(0xFFF5F5F5),
    surfaceContainerLow: Color(0xFFFAFAFA),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFF424242),
    inverseSurface: Color(0xFF212121),
    onInverseSurface: Color(0xFFFFFFFF),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    brightness: Brightness.light,
  );
}

ThemeData _buildAmoled() {
  const colorScheme = ColorScheme.dark(
    surface: Color(0xFF000000),
    onSurface: Color(0xFFEEEEEE),
    primary: Color(0xFF64B5F6),
    primaryContainer: Color(0xFF1A237E),
    onPrimaryContainer: Color(0xFF90CAF9),
    secondary: Color(0xFF64B5F6),
    secondaryContainer: Color(0xFF1B1B1B),
    onSecondaryContainer: Color(0xFFEEEEEE),
    tertiary: Color(0xFF80CBC4),
    onTertiary: Color(0xFF000000),
    tertiaryContainer: Color(0xFF1B1B1B),
    onTertiaryContainer: Color(0xFF80CBC4),
    error: Color(0xFFEF9A9A),
    errorContainer: Color(0xFF2C0B0B),
    onErrorContainer: Color(0xFFEF9A9A),
    outline: Color(0xFF424242),
    outlineVariant: Color(0xFF2C2C2C),
    surfaceContainerHighest: Color(0xFF212121),
    surfaceContainerHigh: Color(0xFF1A1A1A),
    surfaceContainer: Color(0xFF141414),
    surfaceContainerLow: Color(0xFF0A0A0A),
    surfaceContainerLowest: Color(0xFF000000),
    onSurfaceVariant: Color(0xFFBDBDBD),
    inverseSurface: Color(0xFFEEEEEE),
    onInverseSurface: Color(0xFF000000),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    brightness: Brightness.dark,
  );
}

ThemeData _buildSepia() {
  const colorScheme = ColorScheme.light(
    surface: Color(0xFFF4E4C1),
    onSurface: Color(0xFF4E3524),
    primary: Color(0xFF795548),
    onPrimary: Color(0xFFFFF8E1),
    primaryContainer: Color(0xFFD7CCC8),
    onPrimaryContainer: Color(0xFF4E342E),
    secondary: Color(0xFF8D6E63),
    onSecondary: Color(0xFFFFF8E1),
    secondaryContainer: Color(0xFFD7C4A0),
    onSecondaryContainer: Color(0xFF4E3524),
    tertiary: Color(0xFF6D4C41),
    onTertiary: Color(0xFFFFF8E1),
    tertiaryContainer: Color(0xFFD7C4A0),
    onTertiaryContainer: Color(0xFF4E342E),
    error: Color(0xFFC62828),
    onError: Color(0xFFFFF8E1),
    errorContainer: Color(0xFFFFCDD2),
    onErrorContainer: Color(0xFFC62828),
    outline: Color(0xFFBCAAA4),
    outlineVariant: Color(0xFFD7CCC8),
    surfaceContainerHighest: Color(0xFFE0CDAA),
    surfaceContainerHigh: Color(0xFFE6D2AC),
    surfaceContainer: Color(0xFFEAD8B5),
    surfaceContainerLow: Color(0xFFF0DFC0),
    surfaceContainerLowest: Color(0xFFF4E4C1),
    onSurfaceVariant: Color(0xFF6D4C41),
    inverseSurface: Color(0xFF4E3524),
    onInverseSurface: Color(0xFFF4E4C1),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    brightness: Brightness.light,
  );
}
