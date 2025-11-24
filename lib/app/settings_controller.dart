import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/settings_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({required this.settingsService});

  final SettingsService settingsService;

  String _language = 'ar';
  FontFamily _fontFamily = FontFamily.rustam;
  ThemeMode _theme = ThemeMode.system;

  String get language => _language;
  set language(String value) {
    _language = value;
    notifyListeners();
    settingsService.setLanguage(value);
  }

  FontFamily get fontFamily => _fontFamily;
  set fontFamily(FontFamily value) {
    _fontFamily = value;
    notifyListeners();
    settingsService.setFontFamily(value);
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

  Future<void> init() async {
    _theme = await settingsService.loadTheme();
    debugPrint('✅ Loaded settings');
    debugPrint('📏 Theme: $_theme');
    notifyListeners();
  }
}
