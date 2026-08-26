import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:my_quran/app/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/bookmark_service.dart';
import 'package:my_quran/app/services/notes_service.dart';

enum ImportMode { merge, replace }

class BackupPreview {
  const BackupPreview({
    required this.createdAt,
    required this.schemaVersion,
    required this.bookmarkCount,
    required this.categoryCount,
    required this.noteCount,
    required this.appVersion,
    required this.appBuild,
  });

  final DateTime createdAt;
  final int schemaVersion;
  final int categoryCount;
  final int bookmarkCount;
  final int noteCount;
  final String? appVersion;
  final int? appBuild;
}

class BackupService {
  static const String schema = 'com.my_quran.backup';
  static const int schemaVersion = 1;

  final BookmarkService _bookmarkService = BookmarkService();
  final NotesService _notesService = NotesService();

  // Cache (platform channel call)
  static Future<PackageInfo>? _cachedInfoFuture;

  Future<PackageInfo> _packageInfo() {
    return _cachedInfoFuture ??= PackageInfo.fromPlatform();
  }

  int? _tryParseBuild(String buildNumber) => int.tryParse(buildNumber);

  // ---------- Public API ----------

  Future<void> exportAndShare() async {
    final info = await _packageInfo();
    final appVersion = info.version.trim();
    final appBuild = _tryParseBuild(info.buildNumber);

    final bytes = await _exportBytes(
      appVersion: appVersion,
      appBuild: appBuild,
    );

    final String? dir = isMobile
        ? (await getTemporaryDirectory()).path
        : isDesktop
        ? await getDirectoryPath()
        : null;
    if (isDesktop && !kIsWeb && dir == null) return;

    final safeVersion = appVersion.isEmpty ? 'unknown' : appVersion;
    final safeBuild = (appBuild == null) ? '0' : appBuild.toString();

    final fileName =
        'my_quran-backup-v$schemaVersion-$safeVersion+$safeBuild-'
        '${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';

    final file = XFile.fromData(
      bytes,
      name: fileName,
      path: dir != null ? '$dir/$fileName' : null,
      mimeType: 'application/json',
    );
    /// if [path] is null then [file.path] 
    /// will be a Blob URL on web-browsers.
    await file.saveTo(file.path);

    if (isMobile) {
      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          subject: 'My Quran Backup',
          text: 'Backup file (bookmarks + notes).',
        ),
      );
    }
  }

  Future<XFile?> pickBackupFile() async {
    return openFile(
      acceptedTypeGroups: [
        const XTypeGroup(extensions: ['json']),
      ],
    );
  }

  Future<BackupPreview> preview(XFile file) async {
    final doc = await _readBackupDoc(file);
    final data = doc['data'] as Map<String, dynamic>? ?? const {};

    final cats =
        (data['bookmarkCategories'] as List<dynamic>? ?? const []).length;
    final bms = (data['bookmarks'] as List<dynamic>? ?? const []).length;
    final nts = (data['notes'] as List<dynamic>? ?? const []).length;

    final app = doc['app'] as Map?;
    final appVersion = app?['version'] as String?;
    final appBuild = (app?['build'] as num?)?.toInt();

    return BackupPreview(
      createdAt:
          DateTime.tryParse(doc['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      schemaVersion: doc['schemaVersion'] as int? ?? 0,
      categoryCount: cats,
      bookmarkCount: bms,
      noteCount: nts,
      appVersion: appVersion,
      appBuild: appBuild,
    );
  }

  Future<void> import(XFile file, {required ImportMode mode}) async {
    final doc = await _readBackupDoc(file);

    final ver = doc['schemaVersion'] as int? ?? 0;
    if (ver != schemaVersion) {
      throw StateError(
        'Unsupported backup schemaVersion=$ver (supported=$schemaVersion)',
      );
    }

    final data = doc['data'] as Map<String, dynamic>? ?? const {};

    final importedCategories =
        (data['bookmarkCategories'] as List<dynamic>? ?? const [])
            .map((e) => BookmarkCategory.fromJson(e as Map<String, dynamic>))
            .toList();

    final importedBookmarks = (data['bookmarks'] as List<dynamic>? ?? const [])
        .map((e) => VerseBookmark.fromJson(e as Map<String, dynamic>))
        .toList();

    final importedNotes = (data['notes'] as List<dynamic>? ?? const [])
        .map((e) => VerseNote.fromJson(e as Map<String, dynamic>))
        .toList();

    // Ensure default category exists
    final hasDefault = importedCategories.any((c) => c.id == 'default');
    final fixedCategories = hasDefault
        ? importedCategories
        : [
            ...importedCategories,
            ...BookmarkService.defaultCategories.where(
              (c) => c.id == 'default',
            ),
          ];

    // Remap bookmarks with unknown categoryId -> default
    final categoryIds = fixedCategories.map((c) => c.id).toSet();
    final fixedBookmarks = importedBookmarks
        .map(
          (b) => categoryIds.contains(b.categoryId)
              ? b
              : b.copyWith(categoryId: () => 'default'),
        )
        .toList();

    if (mode == ImportMode.replace) {
      await _replaceAll(
        categories: fixedCategories,
        bookmarks: _dedupeBookmarksByVerseKeepLast(fixedBookmarks),
        notes: importedNotes,
      );
      return;
    }

    await _mergeAll(
      categories: fixedCategories,
      bookmarks: fixedBookmarks,
      notes: importedNotes,
    );
  }

  // ---------- Export implementation ----------

  Future<Uint8List> _exportBytes({
    required String appVersion,
    required int? appBuild,
  }) async {
    final categories = await _bookmarkService.getCategories();
    final bookmarks = await _bookmarkService.getBookmarks();
    final notes = await _notesService.getAllNotes();

    final doc = <String, dynamic>{
      'schema': schema,
      'schemaVersion': schemaVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      if (appVersion.isNotEmpty || appBuild != null)
        'app': {
          if (appVersion.isNotEmpty) 'version': appVersion,
          'build': ?appBuild,
        },
      'data': {
        'bookmarkCategories': categories.map((c) => c.toJson()).toList(),
        'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
        'notes': notes.map((n) => n.toJson()).toList(),
      },
    };

    return utf8.encode(jsonEncode(doc));
  }

  // ---------- Import implementation (read/validate) ----------

  Future<Map<String, dynamic>> _readBackupDoc(XFile file) async {
    final bytes = await file.readAsBytes();

    final obj = jsonDecode(utf8.decode(bytes));
    if (obj is! Map<String, dynamic>) {
      throw const FormatException('Backup root is not a JSON object');
    }

    if (obj['schema'] != schema) {
      throw FormatException('Invalid schema: ${obj['schema']}');
    }

    return obj;
  }

  // ---------- Apply strategies ----------

  Future<void> _replaceAll({
    required List<BookmarkCategory> categories,
    required List<VerseBookmark> bookmarks,
    required List<VerseNote> notes,
  }) async {
    await _bookmarkService.replaceCategories(categories);
    await _bookmarkService.replaceBookmarks(bookmarks);
    await _notesService.replaceAll(notes);
  }

  Future<void> _mergeAll({
    required List<BookmarkCategory> categories,
    required List<VerseBookmark> bookmarks,
    required List<VerseNote> notes,
  }) async {
    // Categories: add missing ones, keep local versions for existing ids.
    final localCats = await _bookmarkService.getCategories();
    final localCatIds = localCats.map((c) => c.id).toSet();
    final mergedCats = [
      ...localCats,
      ...categories.where((c) => !localCatIds.contains(c.id)),
    ];
    await _bookmarkService.replaceCategories(mergedCats);

    // Bookmarks: merge by verse (last-write-wins by updatedAt)
    final localBms = await _bookmarkService.getBookmarks();
    final mergedBms = _mergeBookmarksByVerse(localBms, bookmarks);
    await _bookmarkService.replaceBookmarks(mergedBms);

    // Notes: merge by id (allow multiple per verse)
    final localNotes = await _notesService.getAllNotes();
    final mergedNotes = _mergeById<VerseNote>(
      local: localNotes,
      incoming: notes,
      idOf: (n) => n.id,
      updatedAtOf: (n) => n.updatedAt,
    );
    await _notesService.replaceAll(mergedNotes);
  }

  List<VerseBookmark> _mergeBookmarksByVerse(
    List<VerseBookmark> local,
    List<VerseBookmark> incoming,
  ) {
    final map = <String, VerseBookmark>{
      for (final b in local) '${b.surah}:${b.verse}': b,
    };

    for (final b in incoming) {
      final key = '${b.surah}:${b.verse}';
      final existing = map[key];
      if (existing == null || b.updatedAt.isAfter(existing.updatedAt)) {
        map[key] = b;
      }
    }

    return map.values.toList();
  }

  List<T> _mergeById<T>({
    required List<T> local,
    required List<T> incoming,
    required String Function(T) idOf,
    required DateTime Function(T) updatedAtOf,
  }) {
    final map = <String, T>{for (final x in local) idOf(x): x};
    for (final x in incoming) {
      final id = idOf(x);
      final existing = map[id];
      if (existing == null || updatedAtOf(x).isAfter(updatedAtOf(existing))) {
        map[id] = x;
      }
    }
    return map.values.toList();
  }

  List<VerseBookmark> _dedupeBookmarksByVerseKeepLast(
    List<VerseBookmark> items,
  ) {
    final map = <String, VerseBookmark>{};
    for (final b in items) {
      map['${b.surah}:${b.verse}'] = b;
    }
    return map.values.toList();
  }
}
