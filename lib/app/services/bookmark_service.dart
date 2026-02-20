// lib/app/services/bookmark_service.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_quran/app/models.dart';

class BookmarkService {
  factory BookmarkService() => _instance;
  BookmarkService._internal();
  static final BookmarkService _instance = BookmarkService._internal();

  static const String _bookmarksKey = 'verse_bookmarks';
  static const String _categoriesKey = 'bookmark_categories';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ──────────────────────────────────────────────
  // Default categories
  // ──────────────────────────────────────────────

  static final List<BookmarkCategory> defaultCategories = [
    const BookmarkCategory(id: 'default', title: 'عام', color: Colors.blue),
    const BookmarkCategory(
      id: 'memorization',
      title: 'حفظ',
      color: Colors.green,
    ),
    const BookmarkCategory(id: 'review', title: 'مراجعة', color: Colors.orange),
    const BookmarkCategory(id: 'tafsir', title: 'تفسير', color: Colors.purple),
  ];

  // ──────────────────────────────────────────────
  // Categories CRUD
  // ──────────────────────────────────────────────

  Future<List<BookmarkCategory>> getCategories() async {
    final prefs = await _preferences;
    final raw = prefs.getString(_categoriesKey);
    if (raw == null) {
      // First time: persist defaults then return them
      await _saveCategories(defaultCategories);
      return List.from(defaultCategories);
    }
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => BookmarkCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BookmarkCategory?> getCategoryById(String id) async {
    final categories = await getCategories();
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<BookmarkCategory> getCategoriesSync() {
    final raw = _prefs?.getString(_categoriesKey);
    if (raw == null) return List.from(defaultCategories);
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => BookmarkCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addCategory(BookmarkCategory category) async {
    final categories = await getCategories();
    // Ensure unique id
    if (categories.any((c) => c.id == category.id)) return;
    categories.add(category);
    await _saveCategories(categories);
  }

  Future<void> updateCategory(BookmarkCategory category) async {
    final categories = await getCategories();
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index == -1) return;
    categories[index] = category;
    await _saveCategories(categories);
  }

  Future<void> removeCategory(String categoryId) async {
    // Don't allow removing the default category
    if (categoryId == 'default') return;

    final categories = await getCategories();
    categories.removeWhere((c) => c.id == categoryId);
    await _saveCategories(categories);

    // Move bookmarks in this category to 'default'
    final bookmarks = await getBookmarks();
    final updated = bookmarks.map((b) {
      if (b.categoryId == categoryId) {
        return b.copyWith(categoryId: () => 'default');
      }
      return b;
    }).toList();
    await _saveBookmarks(updated);
  }

  Future<void> _saveCategories(List<BookmarkCategory> categories) async {
    final prefs = await _preferences;
    final encoded = jsonEncode(categories.map((c) => c.toJson()).toList());
    await prefs.setString(_categoriesKey, encoded);
  }

  // ──────────────────────────────────────────────
  // Bookmarks CRUD
  // ──────────────────────────────────────────────

  Future<List<VerseBookmark>> getBookmarks() async {
    final prefs = await _preferences;
    final raw = prefs.getString(_bookmarksKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => VerseBookmark.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<VerseBookmark> getBookmarksSync() {
    final raw = _prefs?.getString(_bookmarksKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => VerseBookmark.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  bool isBookmarked(int surah, int verse) {
    final bookmarks = getBookmarksSync();
    return bookmarks.any((b) => b.surah == surah && b.verse == verse);
  }

  VerseBookmark? getBookmarkFor(int surah, int verse) {
    final bookmarks = getBookmarksSync();
    try {
      return bookmarks.firstWhere((b) => b.surah == surah && b.verse == verse);
    } catch (_) {
      return null;
    }
  }

  Future<void> addBookmark(VerseBookmark bookmark) async {
    final bookmarks = await getBookmarks();
    bookmarks.add(bookmark);
    await _saveBookmarks(bookmarks);
  }

  Future<void> updateBookmark(VerseBookmark bookmark) async {
    final bookmarks = await getBookmarks();
    final index = bookmarks.indexWhere((b) => b.id == bookmark.id);
    if (index == -1) return;
    bookmarks[index] = bookmark;
    await _saveBookmarks(bookmarks);
  }

  Future<void> removeBookmarkByVerse(int surah, int verse) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b.surah == surah && b.verse == verse);
    await _saveBookmarks(bookmarks);
  }

  Future<void> removeBookmarkById(String id) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b.id == id);
    await _saveBookmarks(bookmarks);
  }

  Future<List<VerseBookmark>> getBookmarksByCategory(String categoryId) async {
    final bookmarks = await getBookmarks();
    return bookmarks.where((b) => b.categoryId == categoryId).toList();
  }

  Future<void> _saveBookmarks(List<VerseBookmark> bookmarks) async {
    final prefs = await _preferences;
    final encoded = jsonEncode(bookmarks.map((b) => b.toJson()).toList());
    await prefs.setString(_bookmarksKey, encoded);
  }
}
