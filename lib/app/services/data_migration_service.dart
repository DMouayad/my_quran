import 'package:flutter/foundation.dart' show debugPrint;
import 'package:my_quran/app/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:my_quran/app/services/bookmark_service.dart';
import 'package:my_quran/app/services/notes_service.dart';

class DataMigrationService {
  static const _migratedKey = 'migrated_bookmark_notes_v2';

  static Future<void> migrateBookmarkNotesToNotes() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedKey) ?? false) return;

    final bookmarkService = BookmarkService();
    final notesService = NotesService();

    final bookmarks = await bookmarkService.getBookmarks();
    final notes = await notesService.getAllNotes();
    final existingNoteKeys = <String>{
      for (final n in notes) '${n.surah}:${n.verse}:${n.text.trim()}',
    };

    final newNotes = <VerseNote>[];
    var changedBookmarks = false;

    for (final b in bookmarks) {
      final txt = b.note?.trim();
      if (txt == null || txt.isEmpty) continue;

      final dedupeKey = '${b.surah}:${b.verse}:$txt';
      if (!existingNoteKeys.add(dedupeKey)) {
        // already migrated/exists
      } else {
        final now = DateTime.now();
        newNotes.add(
          VerseNote(
            id: const Uuid().v4(),
            surah: b.surah,
            verse: b.verse,
            text: txt,
            createdAt: b.createdAt,
            updatedAt: now,
          ),
        );
      }

      // Clear legacy note field in bookmark
      await bookmarkService.updateBookmark(b.copyWith(note: () => null));
      changedBookmarks = true;
    }

    if (newNotes.isNotEmpty) {
      await notesService.replaceAll([...notes, ...newNotes]);
    }

    await prefs.setBool(_migratedKey, true);

    // Optional logging
    debugPrint(
      '✅ Migration complete: moved ${newNotes.length}'
      ' bookmark notes to notes service '
      '(bookmarksChanged=$changedBookmarks)',
    );
  }
}
