import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:my_quran/app/search/models.dart';
import 'package:my_quran/app/search/processor.dart';

class SearchService {
  static List<String> _sortedKeys = [];

  static Map<String, dynamic> _indexData = {};

  static bool isReady = false;

  static Future<void> init() async {
    if (isReady) return;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/search_index.json',
      );
      final data = await compute(_parseJson, jsonString);

      _sortedKeys = (data['keys'] as List).cast<String>();

      _indexData = data['data'] as Map<String, dynamic>;

      isReady = true;
      debugPrint('🔍 Search index loaded ✅');
    } catch (e) {
      debugPrint('❌ Error loading search index: $e');
    }
  }

  static Map<String, dynamic> _parseJson(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  static List<SearchResult> search(String rawQuery, {bool exactMatch = false}) {
    if (!isReady || rawQuery.trim().isEmpty) return [];

    final rawWords = ArabicTextProcessor.tokenize(rawQuery);
    if (rawWords.isEmpty) return [];

    final normalizedWords = rawWords
        .map(ArabicTextProcessor.normalize)
        .toList();

    final List<Set<int>> matchesPerWord = [];

    for (final word in normalizedWords) {
      final matchesForThisWord = _findMatchesForSingleToken(
        word,
        exactMatch: exactMatch,
      );
      if (matchesForThisWord.isEmpty) return [];
      matchesPerWord.add(matchesForThisWord);
    }

    Set<int> finalIds = matchesPerWord[0];
    for (int i = 1; i < matchesPerWord.length; i++) {
      finalIds = finalIds.intersection(matchesPerWord[i]);
    }

    final results = finalIds.map((id) {
      final surah = id ~/ 1000;
      final verse = id % 1000;
      return SearchResult(surah: surah, verse: verse);
    }).toList();

    results.sort((a, b) {
      if (a.surah != b.surah) return a.surah.compareTo(b.surah);
      return a.verse.compareTo(b.verse);
    });

    return results;
  }

  static Set<int> _findMatchesForSingleToken(
    String token, {
    bool exactMatch = false,
  }) {
    final Set<int> results = {};

    // 1. Exact Match (Always check this)
    if (_indexData.containsKey(token)) {
      final list = _indexData[token] as List;
      results.addAll(list.cast<int>());
    }

    // 2. Prefix Match (Only if exactMatch is FALSE)
    if (!exactMatch) {
      for (final key in _sortedKeys) {
        if (key.compareTo(token) < 0) continue;

        if (!key.startsWith(token)) {
          if (key.length >= token.length &&
              key.substring(0, token.length).compareTo(token) > 0) {
            break;
          }
          continue;
        }

        // Avoid adding the exact match twice
        if (key != token && _indexData.containsKey(key)) {
          final list = _indexData[key] as List;
          results.addAll(list.cast<int>());
        }
      }
    }
    return results;
  }
}
