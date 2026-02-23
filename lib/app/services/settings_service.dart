import 'dart:async';
import 'dart:ui' show FontWeight;

import 'package:flutter/material.dart' show ThemeMode;
import 'package:my_quran/app/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  final _prefs = SharedPreferencesAsync();
  Future<void> setLanguage(String language) async {
    await _prefs.setString('language', language);
  }

  Future<String> loadLanguage() async {
    final language = await _prefs.getString('language') ?? 'ar';
    return language;
  }

  Future<void> setFontFamily(FontFamily fontFamily) async {
    await _prefs.setInt('fontFamily', fontFamily.index);
  }

  Future<FontFamily> loadFontFamily() async {
    final index = await _prefs.getInt('fontFamily');
    if (index != null && index >= 0 && index < FontFamily.values.length) {
      return FontFamily.values[index];
    }
    unawaited(setFontFamily(FontFamily.defaultFontFamily)); // update if invalid
    return FontFamily.defaultFontFamily;
  }

  Future<void> setFontSize(int fontSize) async {
    await _prefs.setInt('fontSize', fontSize);
  }

  Future<int> loadFontSize() async {
    final fontSize = await _prefs.getInt('fontSize') ?? 18;
    return fontSize;
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    await _prefs.setInt('theme', themeMode.index);
  }

  Future<ThemeMode> loadTheme() async {
    final themeIndex = await _prefs.getInt('theme') ?? 0;
    return ThemeMode.values[themeIndex];
  }

  Future<void> setFontWeight(FontWeight fontWeight) async {
    await _prefs.setInt('fontWeight', fontWeight.index);
  }

  Future<FontWeight> loadFontWeight() async {
    final index = await _prefs.getInt('fontWeight');
    if (index != null && index >= 0 && index < FontWeight.values.length) {
      return FontWeight.values[index];
    }
    return FontWeight.w500;
  }

  Future<bool> loadUseTrueBlackBgColor() async {
    return await _prefs.getBool('true_black_bg') ?? false;
  }

  // ignore: avoid_positional_boolean_parameters ()
  Future<void> setUseTrueBlackBgColor(bool value) async {
    await _prefs.setBool('true_black_bg', value);
  }

  // ignore: avoid_positional_boolean_parameters ()
  Future<void> setIsHorizontalScrolling(bool value) async {
    await _prefs.setBool('is_horizontal', value);
  }

  Future<bool> loadIsHorizontalScroling() async {
    return await _prefs.getBool('is_horizontal') ?? false;
  }

  Future<bool> loadKeepScreenOn() async {
    return await _prefs.getBool('keep_screen_on') ?? false;
  }

  // ignore: avoid_positional_boolean_parameters ()
  Future<void> setKeepScreenOn(bool value) async {
    await _prefs.setBool('keep_screen_on', value);
  }
}
