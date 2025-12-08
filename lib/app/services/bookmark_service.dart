import 'package:flutter/foundation.dart';
import 'package:my_quran/app/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BookmarkService {
  factory BookmarkService() => _instance;
  BookmarkService._internal();
  static final BookmarkService _instance = BookmarkService._internal();

  static const String _bookmarksKey = 'quran_bookmarks';

  final List<VerseBookmark> _bookmarks = [];
  final Set<String> _bookmarkedVerseKeys = {}; // For quick lookup
  final _prefs = SharedPreferencesAsync();

  List<VerseBookmark> get bookmarks => List.unmodifiable(_bookmarks);

  Future<void> initialize() async {
    await _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final bookmarksJson = await _prefs.getString(_bookmarksKey);

    if (bookmarksJson != null) {
      final List<dynamic> decoded = jsonDecode(bookmarksJson) as List<dynamic>;
      _bookmarks.clear();
      _bookmarkedVerseKeys.clear();

      for (final item in decoded) {
        final bookmark = VerseBookmark.fromJson(item as Map<String, dynamic>);
        _bookmarks.add(bookmark);
        _bookmarkedVerseKeys.add(bookmark.verseKey);
      }

      debugPrint('📚 Loaded ${_bookmarks.length} bookmarks');
    }
  }

  Future<void> _saveBookmarks() async {
    final bookmarksJson = jsonEncode(
      _bookmarks.map((b) => b.toJson()).toList(),
    );
    await _prefs.setString(_bookmarksKey, bookmarksJson);
  }

  bool isBookmarked(int surah, int verse) {
    return _bookmarkedVerseKeys.contains('$surah:$verse');
  }

  Future<void> addBookmark(VerseBookmark bookmark) async {
    if (!isBookmarked(bookmark.surah, bookmark.verse)) {
      _bookmarks.insert(0, bookmark); // Add to beginning
      _bookmarkedVerseKeys.add(bookmark.verseKey);
      await _saveBookmarks();
      debugPrint('✅ Bookmark added: ${bookmark.verseKey}');
    }
  }

  Future<void> removeBookmark(String id) async {
    final index = _bookmarks.indexWhere((b) => b.id == id);
    if (index != -1) {
      final bookmark = _bookmarks[index];
      _bookmarks.removeAt(index);
      _bookmarkedVerseKeys.remove(bookmark.verseKey);
      await _saveBookmarks();
      debugPrint('❌ Bookmark removed: ${bookmark.verseKey}');
    }
  }

  Future<void> removeBookmarkByVerse(int surah, int verse) async {
    final bookmark = _bookmarks.firstWhere(
      (b) => b.surah == surah && b.verse == verse,
      orElse: () => throw Exception('Bookmark not found'),
    );
    await removeBookmark(bookmark.id);
  }

  Future<void> updateNote(String id, String note) async {
    final index = _bookmarks.indexWhere((b) => b.id == id);
    if (index != -1) {
      final bookmark = _bookmarks[index];
      _bookmarks[index] = VerseBookmark(
        id: bookmark.id,
        surah: bookmark.surah,
        verse: bookmark.verse,
        pageNumber: bookmark.pageNumber,
        verseText: bookmark.verseText,
        createdAt: bookmark.createdAt,
        note: note,
      );
      await _saveBookmarks();
    }
  }

  VerseBookmark? getBookmark(int surah, int verse) {
    try {
      return _bookmarks.firstWhere((b) => b.surah == surah && b.verse == verse);
    } catch (e) {
      return null;
    }
  }
}
