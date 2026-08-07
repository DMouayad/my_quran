import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:my_quran/app/models.dart';

bool get isDesktop {
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows ||
    TargetPlatform.macOS ||
    TargetPlatform.linux => true,
    _ => false,
  };
}

bool get isMobile {
  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };
}

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
