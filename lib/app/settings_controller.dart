import 'dart:async';
import 'dart:ui' show FontWeight;

import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:flutter/material.dart' show ColorScheme, ThemeMode;
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/settings_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({required this.settingsService});

  final SettingsService settingsService;

  String _language = 'ar';
  FontFamily _fontFamily = FontFamily.rustam;
  FontWeight _fontWeight = FontWeight.w500;
  AppTheme _appTheme = AppTheme.myQuran;
  bool _isHorizontalScrolling = false;
  bool _keepScreenOn = true;
  TextAlignOption _textAlign = TextAlignOption.justify;
  bool _supportsDynamicColor = false;
  ColorScheme? _deviceLightScheme;
  ColorScheme? _deviceDarkScheme;
  ThemeMode _themeMode = ThemeMode.system;
  bool _useTrueBlackBgColor = false;
  HizbDisplay _hizbDisplay = HizbDisplay.hidden;

  // ── Getters ──

  bool get supportsDynamicColor => _supportsDynamicColor;
  AppTheme get appTheme => _appTheme;
  bool get keepScreenOn => _keepScreenOn;
  bool get isHorizontalScrolling => _isHorizontalScrolling;
  String get language => _language;
  FontFamily get fontFamily => _fontFamily;
  FontWeight get fontWeight => _fontWeight;
  TextAlignOption get textAlign => _textAlign;

  ThemeMode get themeMode => _themeMode;
  bool get useTrueBlackBgColor => _useTrueBlackBgColor;

  ColorScheme? get deviceLightScheme => _deviceLightScheme;
  ColorScheme? get deviceDarkScheme => _deviceDarkScheme;
  HizbDisplay get hizbDisplay => _hizbDisplay;

  FontWeight get fontWeightForCurrentFamily =>
      fontFamily == FontFamily.rustam ? FontWeight.w500 : _fontWeight;

  // ── Setters ──

  set appTheme(AppTheme value) {
    _appTheme = value;
    notifyListeners();
    settingsService.setAppTheme(value);
  }

  set isHorizontalScrolling(bool value) {
    _isHorizontalScrolling = value;
    notifyListeners();
    settingsService.setIsHorizontalScrolling(value);
  }

  set language(String value) {
    _language = value;
    notifyListeners();
    settingsService.setLanguage(value);
  }

  set fontFamily(FontFamily value) {
    _fontFamily = value;
    settingsService.setFontFamily(value);
    notifyListeners();
  }

  set fontWeight(FontWeight value) {
    _fontWeight = value;
    notifyListeners();
    settingsService.setFontWeight(value);
  }

  set textAlign(TextAlignOption value) {
    _textAlign = value;
    notifyListeners();
    settingsService.setTextAlign(value);
  }

  set themeMode(ThemeMode value) {
    _themeMode = value;
    notifyListeners();
    settingsService.setThemeMode(value);
  }

  set useTrueBlackBgColor(bool value) {
    _useTrueBlackBgColor = value;
    notifyListeners();
    settingsService.setUseTrueBlackBgColor(value);
  }

  set hizbDisplay(HizbDisplay value) {
    _hizbDisplay = value;
    settingsService.setHizbDisplay(value);
    notifyListeners();
  }
  // ── Actions ──

  void toggleThemeMode() {
    _themeMode = switch (_themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    notifyListeners();
    settingsService.setThemeMode(_themeMode);
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

  void setDynamicColorSupport({
    required bool supported,
    ColorScheme? lightScheme,
    ColorScheme? darkScheme,
  }) {
    _supportsDynamicColor = supported;
    _deviceLightScheme = lightScheme;
    _deviceDarkScheme = darkScheme;
  }

  Future<void> init() async {
    _appTheme = await settingsService.loadAppTheme();
    _fontFamily = await settingsService.loadFontFamily();
    _fontWeight = await settingsService.loadFontWeight();
    _isHorizontalScrolling = await settingsService.loadIsHorizontalScroling();
    _themeMode = await settingsService.loadThemeMode();
    _keepScreenOn = await settingsService.loadKeepScreenOn();
    _textAlign = await settingsService.loadTextAlign();
    _useTrueBlackBgColor = await settingsService.loadUseTrueBlackBgColor();
    _hizbDisplay = await settingsService.loadHizbDisplay();

    unawaited(_applyWakelock());

    debugPrint('✅ Loaded settings');
    debugPrint('📏 Theme: $appTheme');
    debugPrint('📏 Font Family: ${_fontFamily.name}');
    debugPrint('📏 Font Weight: ${_fontWeight.value}');
    debugPrint('Keep screen on: $_keepScreenOn');
    debugPrint('Is book mode: $_isHorizontalScrolling');
    notifyListeners();
  }
}
