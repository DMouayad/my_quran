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
  static const double maxFontSize = 60;

  static const double minLineHeight = 1.4;
  static const double maxLineHeight = 3;
  static const double _lineHeightStep = 0.1;

  double _fontSize = _defaultFontSize;
  double get fontSize => _fontSize;

  double? _lineHeight; // null = use font's default
  double? get lineHeight => _lineHeight;

  Future<void> initialize() async {
    _fontSize = await _prefs.getDouble(_fontSizeKey) ?? _defaultFontSize;

    // No stored value = null = default
    final stored = await _prefs.getDouble(_lineHeightKey);
    _lineHeight = stored;

    notifyListeners();
    debugPrint(
      '📏 Font size: $_fontSize, Line height: ${_lineHeight ?? "default"}',
    );
  }

  // ── Line height ──

  Future<void> setLineHeight(double? height) async {
    if (height == null) {
      _lineHeight = null;
      notifyListeners();
      await _prefs.remove(_lineHeightKey);
      return;
    }
    final clamped = double.parse(
      height.clamp(minLineHeight, maxLineHeight).toStringAsFixed(1),
    );
    if (_lineHeight != clamped) {
      _lineHeight = clamped;
      notifyListeners();
      await _prefs.setDouble(_lineHeightKey, clamped);
    }
  }

  void increaseLineHeight() {
    final current = _lineHeight ?? 1.8; // start from a sensible value
    setLineHeight(current + _lineHeightStep);
  }

  void decreaseLineHeight() {
    final current = _lineHeight ?? 1.8;
    setLineHeight(current - _lineHeightStep);
  }

  void resetLineHeight() => setLineHeight(null);

  bool get isAtMinLineHeight =>
      _lineHeight != null && _lineHeight! <= minLineHeight;
  bool get isAtMaxLineHeight =>
      _lineHeight != null && _lineHeight! >= maxLineHeight;
  bool get isDefaultLineHeight => _lineHeight == null;

  // Relative sizes based on base font size
  double get verseFontSize => _fontSize;
  double get verseSymbolFontSize => _fontSize + 2;
  double get surahHeaderFontSize => clampDouble(_fontSize - 3, 14, 24);
  double get pageNumberFontSize => _fontSize + 14;

  final _prefs = SharedPreferencesAsync();

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

  // ── Reset ──

  Future<void> resetFontSize() async => setFontSize(_defaultFontSize);

  // ── Kept for backward compat ──
  bool get isAtMin => isAtMinFont;
  bool get isAtMax => isAtMaxFont;
  bool get isDefault => _fontSize == _defaultFontSize && isDefaultLineHeight;

  double get progress =>
      (_fontSize - minFontSize) / (maxFontSize - minFontSize);
}
