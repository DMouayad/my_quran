import 'dart:async';
import 'dart:ui' show FontWeight;

import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/settings_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({required this.settingsService});

  final SettingsService settingsService;

  String _language = 'ar';
  FontFamily _fontFamily = FontFamily.rustam;
  FontWeight _fontWeight = FontWeight.w500;
  ThemeMode _theme = ThemeMode.system;
  bool _useTrueBlackBgColor = false;
  bool _isHorizontalScrolling = false;

  bool _keepScreenOn = true;
  bool get keepScreenOn => _keepScreenOn;

  bool get isHorizontalScrolling => _isHorizontalScrolling;
  set isHorizontalScrolling(bool value) {
    _isHorizontalScrolling = value;
    notifyListeners();
    settingsService.setIsHorizontalScrolling(value);
  }

  bool get useTrueBlackBgColor => _useTrueBlackBgColor;
  set useTrueBlackBgColor(bool value) {
    _useTrueBlackBgColor = value;
    notifyListeners();
    settingsService.setUseTrueBlackBgColor(value);
  }

  String get language => _language;
  set language(String value) {
    _language = value;
    notifyListeners();
    settingsService.setLanguage(value);
  }

  FontFamily get fontFamily => _fontFamily;

  set fontFamily(FontFamily value) {
    _fontFamily = value;
    settingsService.setFontFamily(value);
    notifyListeners();
  }

  FontWeight get fontWeight => _fontWeight;
  FontWeight get fontWeightForCurrentFamily =>
      fontFamily == FontFamily.rustam ? FontWeight.w500 : _fontWeight;

  set fontWeight(FontWeight value) {
    _fontWeight = value;
    notifyListeners();
    settingsService.setFontWeight(value);
  }

  ThemeMode get themeMode => _theme;
  set themeMode(ThemeMode value) {
    _theme = value;
    notifyListeners();
    settingsService.setTheme(value);
  }

  void toggleTheme() {
    themeMode = switch (themeMode) {
      ThemeMode.system => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.system,
    };
  }

  Future<void> toggleKeepScreenOn() async {
    _keepScreenOn = !_keepScreenOn;
    await _applyWakelock();
    await settingsService.setKeepScreenOn(_keepScreenOn);
    notifyListeners();
  }

  Future<void> _applyWakelock() async {
    if (_keepScreenOn) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
  }

  Future<void> init() async {
    _theme = await settingsService.loadTheme();
    _fontFamily = await settingsService.loadFontFamily();
    _fontWeight = await settingsService.loadFontWeight();
    _useTrueBlackBgColor = await settingsService.loadUseTrueBlackBgColor();
    _isHorizontalScrolling = await settingsService.loadIsHorizontalScroling();
    _keepScreenOn = await settingsService.loadKeepScreenOn();
    debugPrint('✅ Loaded settings');
    debugPrint('📏 Theme: $_theme');
    debugPrint('📏 Font Family: ${_fontFamily.name}');
    debugPrint('📏 Font Weight: ${_fontWeight.value}');
    notifyListeners();
  }
}
