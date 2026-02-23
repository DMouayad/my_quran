import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeController extends ChangeNotifier {
  factory FontSizeController() => _instance;

  FontSizeController._internal();

  static final FontSizeController _instance = FontSizeController._internal();

  static const String _fontSizeKey = 'quran_font_size';
  static const String _lineHeightKey = 'quran_line_height';

  static const double _defaultFontSize = 34;
  static const double minFontSize = 16;
  static const double maxFontSize = 50;

  static const double _defaultLineHeight = 2;
  static const double minLineHeight = 1.4;
  static const double maxLineHeight = 3;
  static const double _lineHeightStep = 0.1;

  double _fontSize = _defaultFontSize;
  double get fontSize => _fontSize;

  double _lineHeight = _defaultLineHeight;
  double get lineHeight => _lineHeight;

  // Relative sizes based on base font size
  double get verseFontSize => _fontSize;
  double get verseSymbolFontSize => _fontSize + 2;
  double get surahHeaderFontSize => clampDouble(_fontSize - 3, 14, 24);
  double get pageNumberFontSize => _fontSize + 14;

  final _prefs = SharedPreferencesAsync();

  Future<void> initialize() async {
    _fontSize = await _prefs.getDouble(_fontSizeKey) ?? _defaultFontSize;
    _lineHeight = await _prefs.getDouble(_lineHeightKey) ?? _defaultLineHeight;
    notifyListeners();
    debugPrint('📏 Font size: $_fontSize, Line height: $_lineHeight');
  }

  // ── Font size ──

  Future<void> setFontSize(double size) async {
    final clampedSize = size.clamp(minFontSize, maxFontSize);
    if (_fontSize != clampedSize) {
      _fontSize = clampedSize;
      notifyListeners();
      await _prefs.setDouble(_fontSizeKey, _fontSize);
    }
  }

  void increaseFontSize([double step = 1.0]) => setFontSize(_fontSize + step);
  void decreaseFontSize([double step = 1.0]) => setFontSize(_fontSize - step);

  bool get isAtMinFont => _fontSize <= minFontSize;
  bool get isAtMaxFont => _fontSize >= maxFontSize;

  // ── Line height ──

  Future<void> setLineHeight(double height) async {
    // Round to 1 decimal to avoid floating point drift
    final clamped = double.parse(
      height.clamp(minLineHeight, maxLineHeight).toStringAsFixed(1),
    );
    if (_lineHeight != clamped) {
      _lineHeight = clamped;
      notifyListeners();
      await _prefs.setDouble(_lineHeightKey, _lineHeight);
    }
  }

  void increaseLineHeight() => setLineHeight(_lineHeight + _lineHeightStep);
  void decreaseLineHeight() => setLineHeight(_lineHeight - _lineHeightStep);

  bool get isAtMinLineHeight => _lineHeight <= minLineHeight;
  bool get isAtMaxLineHeight => _lineHeight >= maxLineHeight;
  bool get isDefaultLineHeight => _lineHeight == _defaultLineHeight;

  // ── Reset ──

  Future<void> resetFontSize() async => setFontSize(_defaultFontSize);
  Future<void> resetLineHeight() async => setLineHeight(_defaultLineHeight);

  // ── Kept for backward compat ──
  bool get isAtMin => isAtMinFont;
  bool get isAtMax => isAtMaxFont;
  bool get isDefault => _fontSize == _defaultFontSize && isDefaultLineHeight;

  double get progress =>
      (_fontSize - minFontSize) / (maxFontSize - minFontSize);
}
