import 'package:flutter/material.dart';

String getArabicNumber(int number) {
  const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return number
      .toString()
      .split('')
      .map((digit) => arabicNumerals[int.parse(digit)])
      .join();
}

extension ThemeContext on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  String? get fontFamily => textTheme.bodyLarge?.fontFamily;
}
