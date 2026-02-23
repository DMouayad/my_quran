import 'dart:async';
import 'dart:ui' show FontWeight;

import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/settings_service.dart';
import 'package:my_quran/app/utils.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({required this.settingsService});

  final SettingsService settingsService;

  String _language = 'ar';
  FontFamily _fontFamily = FontFamily.rustam;
  FontWeight _fontWeight = FontWeight.w500;
  AppTheme _appTheme = AppTheme.light;
  bool _isHorizontalScrolling = false;
  bool _keepScreenOn = true;

  // ── Getters ──

  AppTheme get appTheme => _appTheme;
  ThemeMode get themeMode => _appTheme.themeMode;
  bool get keepScreenOn => _keepScreenOn;
  bool get isHorizontalScrolling => _isHorizontalScrolling;
  String get language => _language;
  FontFamily get fontFamily => _fontFamily;
  FontWeight get fontWeight => _fontWeight;

  // Backward compat: some code checks this
  bool get useTrueBlackBgColor => _appTheme == AppTheme.amoled;

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

  // ── Actions ──

  /// Quick toggle: light↔dark. Returns false if theme needs picker.
  bool toggleTheme() {
    final counterpart = _appTheme.toggleCounterpart;
    if (counterpart != null) {
      appTheme = counterpart;
      return true;
    }
    return false; // caller should show picker
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
    _appTheme = await settingsService.loadAppTheme();

    _fontFamily = await settingsService.loadFontFamily();
    _fontWeight = await settingsService.loadFontWeight();
    _isHorizontalScrolling = await settingsService.loadIsHorizontalScroling();
    _keepScreenOn = await settingsService.loadKeepScreenOn();
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
