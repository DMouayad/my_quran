// ignore_for_file: only_throw_errors (), avoid_dynamic_calls,

import 'dart:async';
import 'dart:convert' show json;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:my_quran/app/models.dart';
import 'package:my_quran/quran/data/hizb_data.dart';

import 'package:my_quran/quran/data/juz_data.dart';
import 'package:my_quran/quran/data/hafs_page_data.dart';
import 'package:my_quran/quran/data/sajdah_verses.dart';
import 'package:my_quran/quran/data/surah_data.dart';
import 'package:my_quran/quran/data/warsh_page_data.dart';

class Quran {
  Quran._();
  static final instance = Quran._();

  /// The text displayed to the user (Visual)
  ValueNotifier<Map<String, dynamic>> data =
      ValueNotifier<Map<String, dynamic>>({});

  /// The text used for Search Logic (Standard Arabic)
  late Map<String, dynamic> _plainTextData;

  late Map<(int, int), int> _verseToPageMap;
  late Map<int, List<int>> _surahToPages;

  /// Monotonic token guarding concurrent riwaya switches: only the latest
  /// `_applyFont` call is allowed to publish. Prevents a slow earlier load
  /// from overwriting a newer one when the user taps Hafs↔Warsh rapidly.
  int _loadToken = 0;

  /// The riwaya of the currently published [data]/[pageData] pair.
  /// Set atomically with the data so readers never see a mixed pair.
  FontFamily _loadedFont = FontFamily.defaultFontFamily;

  /// The riwaya backing the currently published data.
  FontFamily get loadedFont => _loadedFont;

  // --- ASSET PATHS ---
  static const String _medinaPath = 'assets/quran.json';
  static const String _hafsPath = 'assets/kfgqpc_hafs.json';
  static const String _warshPath = 'assets/warsh.json';

  /// Helper to get the correct path
  String _getPathForFont(FontFamily fontFamily) {
    switch (fontFamily) {
      case FontFamily.rustam:
        return _medinaPath;
      case FontFamily.hafs:
        return _hafsPath;
      case FontFamily.warsh:
        return _warshPath;
      case FontFamily.scheherazade:
        return _medinaPath;
    }
  }

  Future<Map<String, dynamic>?> _loadJson(String path) async {
    try {
      final String jsonString = await rootBundle.loadString(path);

      // Parse JSON in a background isolate
      return await compute(_parseJson, jsonString);
    } catch (e) {
      debugPrint('Error loading Quran JSON: $e');
      return null;
    }
  }

  // Pure function must be static or top-level
  static Map<String, dynamic> _parseJson(String jsonString) {
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  Future<void> initialize({FontFamily? fontFamily}) async {
    await _applyFont(fontFamily ?? FontFamily.defaultFontFamily);
  }

  Future<void> useDatasourceForFont(FontFamily fontFamily) async {
    await _applyFont(fontFamily);
  }

  void _buildReverseLookups() {
    _verseToPageMap = {};
    _surahToPages = {};

    for (int pageIndex = 0; pageIndex < pageData.length; pageIndex++) {
      final pageNumber = pageIndex + 1;
      final page = pageData[pageIndex];

      for (final entry in page) {
        final surah = entry['surah']!;
        final start = entry['start']!;
        final end = entry['end']!;

        // Build verse → page map
        for (int verse = start; verse <= end; verse++) {
          _verseToPageMap[(surah, verse)] = pageNumber;
        }

        // Build surah → pages map
        _surahToPages.putIfAbsent(surah, () => []);
        if (!_surahToPages[surah]!.contains(pageNumber)) {
          _surahToPages[surah]!.add(pageNumber);
        }
      }
    }
  }

  static final List<({String arabic, String english, int number})> surahNames =
      surah
          .map(
            (e) => (
              number: e['id']! as int,
              arabic: e['arabic'].toString(),
              english: e['name'].toString(),
            ),
          )
          .toList(growable: false);

  Future<void> _applyFont(FontFamily fontFamily) async {
    final token = ++_loadToken;

    final loadedData = await _loadJson(_getPathForFont(fontFamily));
    if (token != _loadToken) return; // superseded by a newer switch
    if (loadedData == null) {
      throw StateError('Failed to load Quran data.');
    }

    final Map<String, dynamic> plainTextData;
    if (fontFamily == FontFamily.warsh) {
      plainTextData = loadedData;
    } else {
      final plain = await _loadJson(_medinaPath);
      if (token != _loadToken) return; // superseded while loading plain text
      plainTextData = plain ?? {};
    }

    // Publish atomically: pageData + lookups + font first, data.value LAST
    // so the ValueNotifier listeners (cache invalidation + rebuild) always
    // observe a consistent data/pageData pair. Previously data.value was set
    // first, letting visible pages rebuild (and poison the cache) with new
    // data + old pageData — e.g. Hafs text on Warsh pagination, dropping
    // verse 286 of Al-Baqarah until restart. See issue #74.
    pageData = fontFamily.isWarsh ? warshPageData : hafsPageData;
    _buildReverseLookups();
    _plainTextData = plainTextData;
    _loadedFont = fontFamily;
    data.value = loadedData;
  }

  List<List<Map<String, int>>> pageData = [];

  ///Takes [pageNumber] and returns a list containing Surahs and the starting
  /// and ending Verse numbers in that page
  ///
  ///Example:
  ///
  ///```dart
  ///getPageData(604);
  ///```
  ///
  /// Returns List of Page 604:
  ///
  ///```dart
  /// [{surah: 112, start: 1, end: 5}, {surah: 113, start: 1, end: 4},
  ///  {surah: 114, start: 1, end: 5}]
  ///```
  ///
  ///Length of the list is the number of surah in that page.
  List<Map<String, int>> getPageData(int pageNumber) {
    if (pageNumber < 1 || pageNumber > totalPagesCount) {
      throw RangeError.range(pageNumber, 1, totalPagesCount, 'pageNumber');
    }
    return pageData[pageNumber - 1];
  }

  ///The most standard and common copy of Arabic only Quran total pages count
  static const int totalPagesCount = 604;

  ///The constant total of makki surahs
  static const int totalMakkiSurahs = 89;

  ///The constant total of madani surahs
  static const int totalMadaniSurahs = 25;

  ///The constant total juz count
  static const int totalJuzCount = 30;

  ///The constant total surah count
  static const int totalSurahCount = 114;

  ///The constant total verse count
  static const int totalVerseCount = 6236;

  ///The constant 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'
  static const String madinaHafsBasmala =
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  static const String warshBasmala =
      'بِسْمِ اِ۬للَّهِ اِ۬لرَّحْمَٰنِ اِ۬لرَّحِيمِ';

  static const String uthmanicHafsBasmala = '‏ ‏‏ ‏‏‏‏ ‏‏‏‏‏‏ ‏';

  ///The constant 'سَجْدَةٌ'
  static const String sajdah = 'سَجْدَةٌ';

  ///Takes [pageNumber] and returns total surahs count in that page
  int getSurahCountByPage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > 604) {
      throw 'Invalid page number. Page number must be between 1 and 604';
    }
    return pageData[pageNumber - 1].length;
  }

  ///Takes [pageNumber] and returns total verses count in that page
  int getVerseCountByPage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > totalPagesCount) {
      throw RangeError.range(pageNumber, 1, totalPagesCount, 'pageNumber');
    }

    int total = 0;
    for (final entry in pageData[pageNumber - 1]) {
      total += entry['end']! - entry['start']! + 1;
    }
    return total;
  }

  int getJuzNumber(int surahNumber, int verseNumber) {
    for (final juz in juzData) {
      final verses = juz['verses']! as Map<Object?, Object?>;
      if (verses.keys.contains(surahNumber)) {
        final range = verses[surahNumber]! as List<dynamic>;
        if (verseNumber >= (range[0] as int) &&
            verseNumber <= (range[1] as int)) {
          return juz['id']! as int;
        }
      }
    }
    return -1;
  }

  Map<int, List<int>> getSurahAndVersesFromJuz(int juzNumber) {
    return (juzData[juzNumber - 1]['verses']! as Map<Object?, Object?>).map((
      key,
      value,
    ) {
      return MapEntry(key! as int, (value! as List<dynamic>).cast<int>());
    });
  }

  ///Takes [surahNumber] and returns the Surah name
  String getSurahName(int surahNumber) {
    if (surahNumber < 1 || surahNumber > totalSurahCount) {
      throw RangeError.range(surahNumber, 1, totalSurahCount, 'surahNumber');
    }
    return surah[surahNumber - 1]['name']! as String;
  }

  ///Takes [surahNumber] returns the Surah name in Arabic
  String getSurahNameArabic(int surahNumber) {
    if (surahNumber > 114 || surahNumber <= 0) {
      throw RangeError.range(
        surahNumber,
        1,
        totalSurahCount,
        'No Surah found with given surahNumber',
      );
    }
    return surah[surahNumber - 1]['arabic']! as String;
  }

  ///Takes [surahNumber], [verseNumber] and returns the page number of the Quran
  int getPageNumber(int surahNumber, int verseNumber) {
    if (surahNumber < 1 || surahNumber > totalSurahCount) {
      throw RangeError.range(surahNumber, 1, totalSurahCount, 'surahNumber');
    }

    final page = _verseToPageMap[(surahNumber, verseNumber)];
    if (page == null) {
      throw ArgumentError('Invalid verse number.');
    }

    return page;
  }

  /// Clamps [verse] into the loaded riwaya's valid range for [surah] and
  /// resolves the mushaf page for the clamped verse. Falls back to
  /// [fallbackPage] (clamped to 1..604) when the page cannot be resolved.
  /// Used when navigating to a verse stored under another riwaya (e.g. a
  /// Hafs bookmark for 2:286 while Warsh, whose Baqarah ends at 285).
  ({int page, int verse, bool clamped}) resolveNavigation(
    int surah,
    int verse, {
    int? fallbackPage,
  }) {
    if (surah < 1 || surah > totalSurahCount) {
      return (
        page: (fallbackPage ?? 1).clamp(1, totalPagesCount),
        verse: verse,
        clamped: true,
      );
    }
    final max = getVerseCount(surah);
    final clampedVerse = verse.clamp(1, max);
    try {
      return (
        page: getPageNumber(surah, clampedVerse),
        verse: clampedVerse,
        clamped: clampedVerse != verse,
      );
    } catch (_) {
      return (
        page: (fallbackPage ?? 1).clamp(1, totalPagesCount),
        verse: clampedVerse,
        clamped: true,
      );
    }
  }

  ///Takes [surahNumber] and returns the place of revelation (Makkah / Madinah) of the surah
  String getPlaceOfRevelation(int surahNumber) {
    if (surahNumber < 1 || surahNumber > totalSurahCount) {
      throw RangeError.range(surahNumber, 1, totalSurahCount, 'surahNumber');
    }
    return surah[surahNumber - 1]['place'].toString();
  }

  ///Takes [surahNumber] and returns the count of total Verses in the Surah
  /// for the currently loaded riwaya. Verse numbering differs per riwaya
  /// (e.g. Al-Baqarah is 286 in Hafs but 285 in Warsh — 50 surahs differ),
  /// so the static `surah_data` table (Hafs counts) is only a fallback for
  /// before the first dataset finishes loading.
  int getVerseCount(int surahNumber) {
    if (surahNumber > 114 || surahNumber <= 0) {
      throw RangeError.range(surahNumber, 1, totalSurahCount, 'surahNumber');
    }
    final loaded = data.value[surahNumber.toString()] as Map<String, dynamic>?;
    if (loaded != null && loaded.isNotEmpty) return loaded.length;
    return surah[surahNumber - 1]['aya']! as int;
  }

  /// Non-throwing variant of [getVerse]: returns null when the verse does
  /// not exist in the loaded dataset (e.g. Hafs-only verse 286 while Warsh
  /// is active) instead of throwing.
  String? tryGetVerse(
    int surahNumber,
    int verseNumber, {
    bool verseEndSymbol = false,
  }) {
    final surahMap =
        data.value[surahNumber.toString()] as Map<String, dynamic>?;
    final verse = surahMap?[verseNumber.toString()] as String?;
    if (verse == null) return null;
    return verse + (verseEndSymbol ? getVerseEndSymbol(verseNumber) : '');
  }

  ///Takes [surahNumber], [verseNumber] & [verseEndSymbol] (optional) and
  /// returns the Verse in Arabic
  String getVerse(
    int surahNumber,
    int verseNumber, {
    bool verseEndSymbol = false,
  }) {
    final surah = data.value[surahNumber.toString()] as Map<String, dynamic>?;
    final verse = surah?[verseNumber.toString()] as String?;

    if (verse == null) {
      throw 'No verse found with given surahNumber and verseNumber.\n\n';
    }

    return verse + (verseEndSymbol ? getVerseEndSymbol(verseNumber) : '');
  }

  String getVerseInPlainText(int surahNumber, int verseNumber) {
    return (_plainTextData[surahNumber.toString()]
                as Map<String, dynamic>?)?[verseNumber.toString()]
            as String? ??
        '';
  }

  ///Takes [juzNumber] and returns Juz URL (from Quran.com)
  String getJuzURL(int juzNumber) => 'https://quran.com/juz/$juzNumber';

  ///Takes [surahNumber] and returns Surah URL (from Quran.com)
  String getSurahURL(int surahNumber) => 'https://quran.com/$surahNumber';

  ///Takes [surahNumber] & [verseNumber] and returns Verse URL (from Quran.com)
  String getVerseURL(int surahNumber, int verseNumber) =>
      'https://quran.com/$surahNumber/$verseNumber';

  ///Takes [verseNumber], [arabicNumeral] (optional)
  /// and returns '۝' symbol with verse number
  String getVerseEndSymbol(int verseNumber, {bool arabicNumeral = true}) {
    final digits = verseNumber.toString().split('').toList();

    if (!arabicNumeral) return '\u06dd$verseNumber';
    final verseNumBuffer = StringBuffer();

    const arabicNumbers = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };

    for (final e in digits) {
      verseNumBuffer.write(arabicNumbers[e]);
    }

    return '\u06dd$verseNumBuffer';
  }

  ///Takes [surahNumber] and returns the list of page numbers of the surah
  List<int> getSurahPages(int surahNumber) {
    if (surahNumber < 1 || surahNumber > totalSurahCount) {
      throw RangeError.range(surahNumber, 1, totalSurahCount, 'surahNumber');
    }

    return List.unmodifiable(_surahToPages[surahNumber] ?? []);
  }

  ///Takes [surahNumber] & [verseNumber] and returns true if verse is sajdah
  bool isSajdahVerse(int surahNumber, int verseNumber) =>
      sajdahVerses[surahNumber] == verseNumber;

  /// Returns hizb number (1-60) for given surah and verse.
  int getHizbNumber(int surah, int verse) {
    final quarterIndex = _getQuarterIndex(surah, verse);
    return (quarterIndex ~/ 4) + 1;
  }

  /// Returns quarter within the hizb (1-4).
  int getHizbQuarter(int surah, int verse) {
    final quarterIndex = _getQuarterIndex(surah, verse);
    return (quarterIndex % 4) + 1;
  }

  /// Returns true if this verse starts a hizb quarter.
  bool isHizbQuarterStart(int surah, int verse) {
    return hizbQuarterStarts.any((e) => e.$1 == surah && e.$2 == verse);
  }

  /// Hizb quarter index (0-239) for binary search.
  int _getQuarterIndex(int surah, int verse) {
    int result = 0;
    for (int i = hizbQuarterStarts.length - 1; i >= 0; i--) {
      final (s, v) = hizbQuarterStarts[i];
      if (surah > s || (surah == s && verse >= v)) {
        result = i;
        break;
      }
    }
    return result;
  }

  /// Returns the (surah, verse) that starts the given hizb and quarter.
  /// [hizb] is 1-60, [quarter] is 1-4 (1=hizb start, 2=¼, 3=½, 4=¾)
  (int surah, int verse) getHizbQuarterStart(int hizb, {int quarter = 1}) {
    final index = ((hizb - 1) * 4) + (quarter - 1);
    return hizbQuarterStarts[index.clamp(0, hizbQuarterStarts.length - 1)];
  }
}
