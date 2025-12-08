import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class FontSizeController extends ChangeNotifier {
  factory FontSizeController() => _instance;

  FontSizeController._internal();

  static final FontSizeController _instance = FontSizeController._internal();

  static const String _fontSizeKey = 'quran_font_size';
  static const double _defaultFontSize = 24;
  static const double _minFontSize = 16;
  static const double _maxFontSize = 40;

  double _fontSize = _defaultFontSize;
  double get fontSize => _fontSize;

  // Relative sizes based on base font size
  double get verseFontSize => _fontSize;
  double get verseSymbolFontSize => _fontSize + 2;
  double get surahHeaderFontSize => _fontSize - 1;
  double get pageNumberFontSize => _fontSize + 14;

  final _prefs = SharedPreferencesAsync();

  Future<void> initialize() async {
    _fontSize = await _prefs.getDouble(_fontSizeKey) ?? _defaultFontSize;
    notifyListeners();
    debugPrint('📏 Font size loaded: $_fontSize');
  }

  Future<void> setFontSize(double size) async {
    final clampedSize = size.clamp(_minFontSize, _maxFontSize);
    if (_fontSize != clampedSize) {
      _fontSize = clampedSize;
      notifyListeners();

      await _prefs.setDouble(_fontSizeKey, _fontSize);
      debugPrint('📏 Font size saved: $_fontSize');
    }
  }

  void increaseFontSize([double step = 2.0]) {
    setFontSize(_fontSize + step);
  }

  void decreaseFontSize([double step = 2.0]) {
    setFontSize(_fontSize - step);
  }

  Future<void> resetFontSize() async {
    await setFontSize(_defaultFontSize);
  }

  bool get isAtMin => _fontSize <= _minFontSize;
  bool get isAtMax => _fontSize >= _maxFontSize;
  bool get isDefault => _fontSize == _defaultFontSize;

  double get progress =>
      (_fontSize - _minFontSize) / (_maxFontSize - _minFontSize);
}
