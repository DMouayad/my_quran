// ignore_for_file: avoid_positional_boolean_parameters (ok for one param)

import 'dart:async';
import 'dart:ui' show FontWeight;

import 'package:flutter/material.dart' show ThemeMode;
import 'package:my_quran/app/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _appThemeKey = 'app_theme';
  static const String _trueBlackKey = 'true_black';
  static const String _hizbDisplayKey = 'hizb_display';

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

  Future<void> setIsHorizontalScrolling(bool value) async {
    await _prefs.setBool('is_horizontal', value);
  }

  Future<bool> loadIsHorizontalScroling() async {
    return await _prefs.getBool('is_horizontal') ?? false;
  }

  Future<bool> loadKeepScreenOn() async {
    return await _prefs.getBool('keep_screen_on') ?? false;
  }

  Future<void> setKeepScreenOn(bool value) async {
    await _prefs.setBool('keep_screen_on', value);
  }

  Future<AppTheme> loadAppTheme() async {
    final value = await _prefs.getString(_appThemeKey);
    return AppTheme.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppTheme.myQuran,
    );
  }

  Future<void> setAppTheme(AppTheme theme) async {
    await _prefs.setString(_appThemeKey, theme.name);
  }

  static const String _textAlignKey = 'text_align';

  Future<TextAlignOption> loadTextAlign() async {
    final value = await _prefs.getString(_textAlignKey);
    return TextAlignOption.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TextAlignOption.justify,
    );
  }

  static const String _themeModeKey = 'theme_mode';
  Future<void> setTextAlign(TextAlignOption align) async {
    await _prefs.setString(_textAlignKey, align.name);
  }

  Future<ThemeMode> loadThemeMode() async {
    final value = await _prefs.getString(_themeModeKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setUseTrueBlackBgColor(bool value) async {
    await _prefs.setBool(_trueBlackKey, value);
  }

  Future<bool> loadUseTrueBlackBgColor() async {
    return await _prefs.getBool(_trueBlackKey) ?? false;
  }

  Future<void> setHizbDisplay(HizbDisplay value) async {
    await _prefs.setString(_hizbDisplayKey, value.name);
  }

  Future<HizbDisplay> loadHizbDisplay() async {
    final name = await _prefs.getString(_hizbDisplayKey);
    try {
      return name == null
          ? HizbDisplay.hidden
          : HizbDisplay.values.byName(name);
    } catch (e) {
      return HizbDisplay.hidden;
    }
  }
}
