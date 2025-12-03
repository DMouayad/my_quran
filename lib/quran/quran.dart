// ignore_for_file: only_throw_errors (), avoid_dynamic_calls,
// ignore_for_file: argument_type_not_assignable ()

import 'dart:convert' show json;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:my_quran/quran/data/juz_data.dart';
import 'package:my_quran/quran/data/page_data.dart';
import 'package:my_quran/quran/data/sajdah_verses.dart';
import 'package:my_quran/quran/data/surah_data.dart';

///Supported audio reciters for CDN islamic.network
///Defaults to [Reciter.arAlafasy] to preserve existing behavior.
enum Reciter {
  arAlafasy('ar.alafasy', 'Alafasy'),
  arHusary('ar.husary', 'Husary'),
  arAhmedAjamy('ar.ahmedajamy', 'Ahmed al-Ajamy'),
  arHudhaify('ar.hudhaify', 'Hudhaify'),
  arMaherMuaiqly('ar.mahermuaiqly', 'Maher Al Muaiqly'),
  arMuhammadAyyoub('ar.muhammadayyoub', 'Muhammad Ayyoub'),
  arMuhammadJibreel('ar.muhammadjibreel', 'Muhammad Jibreel'),
  arMinshawi('ar.minshawi', 'Minshawi'),
  arShaatree('ar.shaatree', 'Abu Bakr Ash-Shaatree');

  final String code;
  final String englishName;
  const Reciter(this.code, this.englishName);
}

enum SurahSeparator {
  none,
  surahName,
  surahNameArabic,
  surahNameEnglish,
  surahNameTurkish,
  surahNameFrench,
  surahNameRussian,
}

class Quran {
  Quran._();
  static final instance = Quran._();

  static Map<String, dynamic> _data = {};

  static Future<void> initialize() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/quran.json',
      );
      _data = json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading Quran JSON: $e');
    }
  }

  ///Takes [pageNumber] and returns a list containing Surahs and the starting and ending Verse numbers in that page
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
  /// [{surah: 112, start: 1, end: 5}, {surah: 113, start: 1, end: 4}, {surah: 114, start: 1, end: 5}]
  ///```
  ///
  ///Length of the list is the number of surah in that page.
  List<dynamic> getPageData(int pageNumber) {
    if (pageNumber < 1 || pageNumber > 604) {
      throw 'Invalid page number. Page number must be between 1 and 604';
    }
    return pageData[pageNumber - 1] as List<dynamic>;
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
  static const String basmala = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  ///The constant 'سَجْدَةٌ'
  static const String sajdah = 'سَجْدَةٌ';

  ///Takes [pageNumber] and returns total surahs count in that page
  int getSurahCountByPage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > 604) {
      throw 'Invalid page number. Page number must be between 1 and 604';
    }
    return (pageData[pageNumber - 1] as List<dynamic>).length;
  }

  ///Takes [pageNumber] and returns total verses count in that page
  int getVerseCountByPage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > 604) {
      throw 'Invalid page number. Page number must be between 1 and 604';
    }
    int totalVerseCount = 0;
    for (
      int i = 0;
      i < (pageData[pageNumber - 1] as List<dynamic>).length;
      i++
    ) {
      totalVerseCount += int.parse(
        pageData[pageNumber - 1][i]!['end'].toString(),
      );
    }
    return totalVerseCount;
  }

  ///Takes [surahNumber] & [verseNumber] and returns Juz number
  int getJuzNumber(int surahNumber, int verseNumber) {
    for (final juz in juzData) {
      final verses = juz['verses'] as Map<int, List<int>>;
      if (verses.keys.contains(surahNumber)) {
        if (verseNumber >= verses[surahNumber]![0] &&
            verseNumber <= verses[surahNumber]![1]) {
          return int.parse(juz['id'].toString());
        }
      }
    }
    return -1;
  }

  ///Takes [juzNumber] and returns a map which contains keys as surah number and value as a list containing starting and ending verse numbers.
  ///
  ///Example:
  ///
  ///```dart
  ///getSurahAndVersesListFromJuz(1);
  ///```
  ///
  /// Returns Map of Juz 1:
  ///
  ///```dart
  /// Map<int, List<int>> surahAndVerses = {
  ///        1: [1, 7],
  ///        2: [1, 141] //2 is surahNumber, 1 is starting verse and 141 is ending verse number
  /// };
  ///
  /// print(surahAndVerseList[1]); //[1, 7] => starting verse : 1, ending verse: 7
  ///```
  Map<int, List<int>> getSurahAndVersesFromJuz(int juzNumber) {
    return juzData[juzNumber - 1]['verses'] as Map<int, List<int>>;
  }

  ///Takes [surahNumber] and returns the Surah name
  String getSurahName(int surahNumber) {
    if (surahNumber > 114 || surahNumber <= 0) {
      throw 'No Surah found with given surahNumber';
    }
    return surah[surahNumber - 1]['name'].toString();
  }

  ///Takes [surahNumber] returns the Surah name in Arabic
  String getSurahNameArabic(int surahNumber) {
    if (surahNumber > 114 || surahNumber <= 0) {
      throw 'No Surah found with given surahNumber';
    }
    return surah[surahNumber - 1]['arabic'].toString();
  }

  ///Takes [surahNumber], [verseNumber] and returns the page number of the Quran
  int getPageNumber(int surahNumber, int verseNumber) {
    if (surahNumber > 114 || surahNumber <= 0) {
      throw 'No Surah found with given surahNumber';
    }

    for (int pageIndex = 0; pageIndex < pageData.length; pageIndex++) {
      for (
        int surahIndexInPage = 0;
        surahIndexInPage < pageData[pageIndex].length;
        surahIndexInPage++
      ) {
        final e = pageData[pageIndex][surahIndexInPage];
        if (e['surah'] == surahNumber &&
            (e['start'] as int) <= verseNumber &&
            (e['end'] as int) >= verseNumber) {
          return pageIndex + 1;
        }
      }
    }

    throw 'Invalid verse number.';
  }

  ///Takes [surahNumber] and returns the place of revelation (Makkah / Madinah) of the surah
  String getPlaceOfRevelation(int surahNumber) {
    if (surahNumber > 114 || surahNumber <= 0) {
      throw 'No Surah found with given surahNumber';
    }
    return surah[surahNumber - 1]['place'].toString();
  }

  ///Takes [surahNumber] and returns the count of total Verses in the Surah
  int getVerseCount(int surahNumber) {
    if (surahNumber > 114 || surahNumber <= 0) {
      throw 'No verse found with given surahNumber';
    }
    return int.parse(surah[surahNumber - 1]['aya'].toString());
  }

  ///Takes [surahNumber], [verseNumber] & [verseEndSymbol] (optional) and returns the Verse in Arabic
  String getVerse(
    int surahNumber,
    int verseNumber, {
    bool verseEndSymbol = false,
  }) {
    final verse = _data[surahNumber.toString()]?[verseNumber.toString()]
        .toString();

    if (verse == null) {
      throw 'No verse found with given surahNumber and verseNumber.\n\n';
    }

    return verse + (verseEndSymbol ? getVerseEndSymbol(verseNumber) : '');
  }

  ///Takes [juzNumber] and returns Juz URL (from Quran.com)
  String getJuzURL(int juzNumber) => 'https://quran.com/juz/$juzNumber';

  ///Takes [surahNumber] and returns Surah URL (from Quran.com)
  String getSurahURL(int surahNumber) => 'https://quran.com/$surahNumber';

  ///Takes [surahNumber] & [verseNumber] and returns Verse URL (from Quran.com)
  String getVerseURL(int surahNumber, int verseNumber) =>
      'https://quran.com/$surahNumber/$verseNumber';

  ///Takes [verseNumber], [arabicNumeral] (optional) and returns '۝' symbol with verse number
  String getVerseEndSymbol(int verseNumber, {bool arabicNumeral = true}) {
    var arabicNumeric = '';
    final digits = verseNumber.toString().split('').toList();

    if (!arabicNumeral) return '\u06dd${verseNumber}';

    const Map arabicNumbers = {
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
      arabicNumeric += arabicNumbers[e].toString();
    }

    return '\u06dd$arabicNumeric';
  }

  ///Takes [surahNumber] and returns the list of page numbers of the surah
  List<int> getSurahPages(int surahNumber) {
    if (surahNumber > 114 || surahNumber <= 0) {
      throw 'Invalid surahNumber';
    }

    const pagesCount = totalPagesCount;
    final List<int> pages = [];
    for (int currentPage = 1; currentPage <= pagesCount; currentPage++) {
      final pageData = getPageData(currentPage);
      for (int j = 0; j < pageData.length; j++) {
        final currentSurahNum = pageData[j]['surah'];
        if (currentSurahNum == surahNumber) {
          pages.add(currentPage);
          break;
        }
      }
    }
    return pages;
  }

  ///Takes [pageNumber], [verseEndSymbol], [SurahSeparator] & [customSurahSeparator] and returns the list of verses in that page
  ///if [customSurahSeparator] is given, [SurahSeparator] will not work.
  List<String> getVersesTextByPage(
    int pageNumber, {
    bool verseEndSymbol = false,
    SurahSeparator surahSeparator = SurahSeparator.none,
    String customSurahSeparator = '',
  }) {
    if (pageNumber > 604 || pageNumber <= 0) {
      throw 'Invalid pageNumber';
    }

    final List<String> verses = [];
    final pageData = getPageData(pageNumber);
    for (final data in pageData) {
      final surahDataInPage = data as Map<String, dynamic>;
      if (customSurahSeparator != '') {
        verses.add(customSurahSeparator);
      } else if (surahSeparator == SurahSeparator.surahName) {
        verses.add(getSurahName(surahDataInPage['surah'] as int));
      } else if (surahSeparator == SurahSeparator.surahNameArabic) {
        verses.add(getSurahNameArabic(surahDataInPage['surah'] as int));
      }
      for (int j = data['start'] as int; j <= (data['end'] as int); j++) {
        verses.add(
          getVerse(data['surah'] as int, j, verseEndSymbol: verseEndSymbol),
        );
      }
    }
    return verses;
  }

  ///Takes [surahNumber] and returns audio URL of that surah
  String getAudioURLBySurah(
    int surahNumber, {
    Reciter reciter = Reciter.arAlafasy,
    int bitrate = 128,
  }) =>
      'https://cdn.islamic.network/quran/audio-surah/$bitrate/${reciter.code}/$surahNumber.mp3';

  ///Takes [surahNumber] & [verseNumber] and returns audio URL of that verse
  String getAudioURLByVerse(
    int surahNumber,
    int verseNumber, {
    Reciter reciter = Reciter.arAlafasy,
    int bitrate = 128,
  }) {
    int verseNum = 0;

    // Calculate absolute verse number by counting all verses before this one
    for (int i = 1; i < surahNumber; i++) {
      verseNum += (_data[i.toString()]?.length as int?) ?? 0;
    }
    verseNum += verseNumber;

    return 'https://cdn.islamic.network/quran/audio/$bitrate/${reciter.code}/$verseNum.mp3';
  }

  ///Takes [surahNumber] & [verseNumber] and returns true if verse is sajdah
  bool isSajdahVerse(int surahNumber, int verseNumber) =>
      sajdahVerses[surahNumber] == verseNumber;

  ///Takes [verseNumber] and returns audio URL of that verse
  String getAudioURLByVerseNumber(
    int verseNumber, {
    Reciter reciter = Reciter.arAlafasy,
    int bitrate = 128,
  }) =>
      'https://cdn.islamic.network/quran/audio/$bitrate/${reciter.code}/$verseNumber.mp3';
}
