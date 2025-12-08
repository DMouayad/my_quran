import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_quran/app/models.dart';

class ReadingPositionService {
  static const String _key = 'last_reading_position';
  static final _prefs = SharedPreferencesAsync();

  static Future<void> savePosition(ReadingPosition position) async {
    await _prefs.setString(_key, jsonEncode(position.toJson()));
  }

  static Future<ReadingPosition?> loadPosition() async {
    final jsonString = await _prefs.getString(_key);

    if (jsonString != null) {
      return ReadingPosition.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );
    }
    return null;
  }

  static Future<void> clearPosition() async {
    await _prefs.remove(_key);
  }
}
