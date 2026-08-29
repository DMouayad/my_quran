import 'package:flutter/widgets.dart';

class Surah {
  const Surah({
    required this.arabicName,
    required this.id,
    required this.name,
    required this.revelationPlace,
    required this.verseCount,
  });

  final int id;
  final int verseCount;
  final String revelationPlace;
  final String name;
  final String arabicName;
}

typedef Verse = ({int number, String text});

class SurahInPage {
  const SurahInPage({required this.surahNumber, required this.verses});

  final int surahNumber;
  Verse? get firstVerse => verses.firstOrNull;
  Verse? get lastVerse => verses.lastOrNull;
  final List<Verse> verses;

  /// Returns true if this surah has Basmala.
  ///
  /// It will return false for "Al-Fatihah" and "At-Tawbah".
  bool get hasBasmala => surahNumber != 1 && surahNumber != 9;
  bool get isAlfatihah => surahNumber == 1;
}

class QuranPage {
  const QuranPage({required this.pageNumber, required this.surahs});
  final int pageNumber;
  final List<SurahInPage> surahs;
}

class PageLocation {
  PageLocation({
    required this.pageNumber,
    required this.surahNumber,
    required this.surahName,
  });
  final int pageNumber;
  final int surahNumber;
  final String surahName;
}

class ReadingPosition {
  const ReadingPosition({
    required this.hizbNumber,
    required this.hizbQuarter,
    required this.pageNumber,
    required this.surahNumber,
    required this.verseNumber,
    required this.juzNumber,
  });
  factory ReadingPosition.fromJson(Map<String, dynamic> json) =>
      ReadingPosition(
        pageNumber: json['pageNumber'] as int,
        surahNumber: json['surahNumber'] as int,
        verseNumber: json['verseNumber'] as int,
        juzNumber: json['juzNumber'] as int,
        hizbNumber: json['hizbNumber'] as int? ?? 1,
        hizbQuarter: json['hizbQuarter'] as int? ?? 1,
      );
  final int pageNumber;
  final int surahNumber;
  final int verseNumber;
  final int juzNumber;
  final int hizbNumber;
  final int hizbQuarter;

  @override
  String toString() =>
      'Page: $pageNumber, Surah: $surahNumber, Verse: $verseNumber, '
      'Juz: $juzNumber';

  Map<String, dynamic> toJson() => {
    'pageNumber': pageNumber,
    'surahNumber': surahNumber,
    'verseNumber': verseNumber,
    'juzNumber': juzNumber,
    'hizbNumber': hizbNumber,
    'hizbQuarter': hizbQuarter,
  };
}

@immutable
class BookmarkCategory {
  const BookmarkCategory({
    required this.id,
    required this.title,
    required this.color,
  });

  factory BookmarkCategory.fromJson(Map<String, dynamic> json) {
    return BookmarkCategory(
      id: json['id'] as String,
      title: json['title'] as String,
      color: Color(json['color'] as int),
    );
  }

  final String id;
  final String title;
  final Color color;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'color': color.toARGB32(),
  };

  BookmarkCategory copyWith({String? id, String? title, Color? color}) {
    return BookmarkCategory(
      id: id ?? this.id,
      title: title ?? this.title,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class VerseNote {
  const VerseNote({
    required this.id,
    required this.surah,
    required this.verse,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VerseNote.fromJson(Map<String, dynamic> json) {
    return VerseNote(
      id: json['id'] as String,
      surah: json['surah'] as int,
      verse: json['verse'] as int,
      text: json['text'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
    );
  }

  final String id;
  final int surah;
  final int verse;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'surah': surah,
    'verse': verse,
    'text': text,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  VerseNote copyWith({String? text, DateTime? updatedAt}) {
    return VerseNote(
      id: id,
      surah: surah,
      verse: verse,
      text: text ?? this.text,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VerseBookmark {
  VerseBookmark({
    required this.id,
    required this.surah,
    required this.verse,
    required this.pageNumber,
    required this.createdAt,
    DateTime? updatedAt,
    @Deprecated(
      'Legacy field. Notes are stored in NotesService now; kept only for migration/backward compatibility.',
    )
    this.note,
    this.categoryId,
  }) : updatedAt = updatedAt ?? createdAt;

  factory VerseBookmark.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      json['createdAt'] as int,
    );

    final updatedAtMs = json['updatedAt'];
    final updatedAt = updatedAtMs is int
        ? DateTime.fromMillisecondsSinceEpoch(updatedAtMs)
        : createdAt;

    return VerseBookmark(
      id: json['id'] as String,
      surah: json['surah'] as int,
      verse: json['verse'] as int,
      pageNumber: json['pageNumber'] as int,
      createdAt: createdAt,
      updatedAt: updatedAt,
      note: json['note'] as String?, // legacy
      categoryId: json['categoryId'] as String?,
    );
  }

  final String id;
  final int surah;
  final int verse;
  final int pageNumber;

  /// Creation time (stable)
  final DateTime createdAt;

  /// Last modification time (used for future-proof merge/sync rules)
  final DateTime updatedAt;

  @Deprecated(
    'Legacy field. Notes are stored in NotesService now; '
    'kept only for migration/backward compatibility.',
  )
  final String? note;

  final String? categoryId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'surah': surah,
    'verse': verse,
    'pageNumber': pageNumber,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'note': note, // legacy (keep for now)
    'categoryId': categoryId,
  };

  VerseBookmark copyWith({
    String? id,
    int? surah,
    int? verse,
    int? pageNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? Function()? note,
    String? Function()? categoryId,
  }) {
    final newCreatedAt = createdAt ?? this.createdAt;
    return VerseBookmark(
      id: id ?? this.id,
      surah: surah ?? this.surah,
      verse: verse ?? this.verse,
      pageNumber: pageNumber ?? this.pageNumber,
      createdAt: newCreatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note != null ? note() : this.note,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
    );
  }
}

enum FontFamily {
  hafs,
  rustam,
  warsh,
  scheherazade;

  static FontFamily get defaultFontFamily => hafs;
  static FontFamily get arabicNumbersFontFamily => scheherazade;

  bool get isHafs => this == hafs;
  bool get isWarsh => this == warsh;

  String get name {
    return switch (this) {
      FontFamily.hafs => 'Hafs',
      FontFamily.rustam => 'Rustam',
      FontFamily.scheherazade => 'Scheherazade',
      FontFamily.warsh => 'Warsh',
    };
  }
}

enum AppTheme {
  myQuran,
  sepia,
  dynamic, // device Material You
}

enum TextAlignOption {
  justify, // ضبط
  center, // توسيط
  start, // محاذاة لليمين
}

enum HizbDisplay {
  hidden,
  replaceJuz,
  replaceJuzWithQuarter;

  bool get isHidden => this == hidden;
  bool get isReplaceJuz => this == replaceJuz || this == replaceJuzWithQuarter;
  bool get withQuarter => this == replaceJuzWithQuarter;
}

enum SearchMatchMode {
  auto,
  exact,
  prefix,
  contains,
  flexible;

  bool get isAuto => this == auto;
}

enum SearchOperator { and, or }

enum SettingSection { general, appearance, backup }

class SearchHit {
  const SearchHit({
    required this.surah,
    required this.verse,
    required this.matchedWordIndexes,
  });

  final int surah;
  final int verse;

  /// Indexes into the verse "content words"
  ///  (after filtering marks-only tokens).
  final List<int> matchedWordIndexes;
}

class SearchResponse {
  const SearchResponse({
    required this.isTruncated,
    required this.totalHits,
    required this.hits,
    required this.effectiveMode,
    required this.normalizedQueryTokens,
    required this.operatorUsed,
  });

  final List<SearchHit> hits;
  final SearchMatchMode effectiveMode;
  final Set<String> normalizedQueryTokens;
  final SearchOperator operatorUsed;
  final int totalHits;
  final bool isTruncated;
}
