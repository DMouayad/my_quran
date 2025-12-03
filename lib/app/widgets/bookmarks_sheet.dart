import 'package:flutter/material.dart';

import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/bookmark_service.dart';
import 'package:my_quran/quran/quran.dart';

class BookmarksSheet extends StatefulWidget {
  const BookmarksSheet({required this.onNavigateToPage, super.key});
  final void Function({
    required int page,
    required int surah,
    required int verse,
  })
  onNavigateToPage;

  @override
  State<BookmarksSheet> createState() => _BookmarksSheetState();
}

class _BookmarksSheetState extends State<BookmarksSheet> {
  final BookmarkService _bookmarkService = BookmarkService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bookmarks = _bookmarkService.bookmarks;

    return bookmarks.isEmpty
        ? _buildEmptyState(colorScheme)
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index];
              return _BookmarkCard(
                bookmark: bookmark,
                onTap: () {
                  widget.onNavigateToPage(
                    page: bookmark.pageNumber,
                    surah: bookmark.surah,
                    verse: bookmark.verse,
                  );
                  Navigator.pop(context);
                },
                onDelete: () => _deleteBookmark(bookmark.id),
                onAddNote: () => _showAddNoteDialog(bookmark),
              );
            },
          );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد علامات مرجعية',
            style: TextStyle(fontSize: 18, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط مطولاً على أي آية لإضافة علامة',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBookmark(String id) async {
    await _bookmarkService.removeBookmark(id);
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف العلامة')));
    }
  }

  void _showAddNoteDialog(VerseBookmark bookmark) {
    final controller = TextEditingController(text: bookmark.note ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة ملاحظة'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'اكتب ملاحظتك هنا...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await _bookmarkService.updateNote(bookmark.id, controller.text);
              setState(() {});
              if (!context.mounted) {
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('تم حفظ الملاحظة')));
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({
    required this.bookmark,
    required this.onTap,
    required this.onDelete,
    required this.onAddNote,
  });
  final VerseBookmark bookmark;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                spacing: 10,
                children: [
                  // Icon(Icons.bookmark, color: colorScheme.primary, size: 20),
                  Text(
                    Quran.instance.getSurahNameArabic(bookmark.surah),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ص ${_toArabicNumber(bookmark.pageNumber)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: FontFamily.defaultFontFamily.name,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.bookmark_remove, size: 20),
                    onPressed: onDelete,
                    tooltip: 'حذف',
                    color: colorScheme.error,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Verse text
              Text(
                bookmark.verseText,
                style: const TextStyle(fontSize: 18, height: 1.8),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.justify,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              if (bookmark.note != null && bookmark.note!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bookmark.note!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Actions
              Row(
                children: [
                  Text(
                    _formatDate(bookmark.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.note_add, size: 20),
                    onPressed: onAddNote,
                    tooltip: 'إضافة ملاحظة',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'اليوم';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _toArabicNumber(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((digit) => arabicNumerals[int.parse(digit)])
        .join();
  }
}
