import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:my_quran/app/search/models.dart';
import 'package:my_quran/app/search/processor.dart';

class SearchService {
  static List<String> _sortedKeys = [];

  static Map<String, dynamic> _indexData = {};

  // Track current loaded type to avoid reloading the same file
  static String _currentType = '';
  static bool isReady = false;

  /// Initialize or Switch Index
  /// [fontFamily]: 'hafs', 'warsh', 'rustam', etc.
  static Future<void> init(String fontFamily) async {
    // Determine target file
    String targetFile;
    if (fontFamily.toLowerCase() == 'warsh') {
      targetFile = 'assets/search_index_warsh.json';
    } else {
      // Default to Hafs for 'hafs', 'rustam', or anything else
      targetFile = 'assets/search_index_hafs.json';
    }

    // Optimization: Don't reload if we already have this index
    if (isReady && _currentType == targetFile) return;

    isReady = false;
    _currentType = targetFile;

    try {
      final jsonString = await rootBundle.loadString(targetFile);

      // Parse in Isolate
      final data = await compute(_parseJson, jsonString);

      _sortedKeys = (data['keys'] as List).cast<String>();
      _indexData = data['data'] as Map<String, dynamic>;

      isReady = true;
      debugPrint('🔍 Search index loaded: $targetFile ✅');
    } catch (e) {
      debugPrint('❌ Error loading search index: $e');
      isReady = false;
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

    // 1. Exact Match
    if (_indexData.containsKey(token)) {
      final list = _indexData[token] as List;
      results.addAll(list.cast<int>());
    }

    // 2. Prefix Match (if enabled)
    if (!exactMatch) {
      // Find the first key that is not smaller than the
      // token using binary search
      final startIndex = lowerBound(_sortedKeys, token);

      // Iterate from the start index as long as keys start with the token
      for (int i = startIndex; i < _sortedKeys.length; i++) {
        final key = _sortedKeys[i];
        if (key.startsWith(token)) {
          // Avoid adding the exact match twice
          if (key != token && _indexData.containsKey(key)) {
            final list = _indexData[key] as List;
            results.addAll(list.cast<int>());
          }
        } else {
          // Since the list is sorted, we can stop as soon as we find a key
          // that doesn't start with the token.
          break;
        }
      }
    }

    return results;
  }
}
