import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_quran/app/pages/bookmark_categories_page.dart';
import 'package:my_quran/app/services/notes_service.dart';
import 'package:my_quran/app/settings_controller.dart';
import 'package:my_quran/app/widgets/edit_note_dialog.dart';
import 'package:my_quran/app/widgets/overlay.dart';
import 'package:my_quran/app/widgets/verse_notes_manager.dart';

import 'package:my_quran/quran/quran.dart';

import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/bookmark_service.dart';
import 'package:my_quran/app/utils.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({
    required this.settingsController,
    required this.onNavigateToPage,
    super.key,
    this.onBookmarkChanged,
  });
  final void Function({
    required int page,
    required int surah,
    required int verse,
  })
  onNavigateToPage;
  final SettingsController settingsController;
  final VoidCallback? onBookmarkChanged;

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final _bookmarkService = BookmarkService();

  List<VerseBookmark> _allBookmarks = [];
  List<BookmarkCategory> _categories = [];
  String? _selectedCategoryId; // null = show all
  bool _loading = true;
  final _notesService = NotesService();
  Map<String, List<VerseNote>> _notesByVerse = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Reload data and notify parent that bookmarks changed.
  Future<void> _reloadAndNotify() async {
    await _load();
    widget.onBookmarkChanged?.call();
  }

  Future<void> _load() async {
    final bookmarks = await _bookmarkService.getBookmarks();
    final categories = await _bookmarkService.getCategories();
    final notes = await _notesService.getAllNotes();

    // newest first
    bookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final map = <String, List<VerseNote>>{};
    for (final n in notes) {
      final key = '${n.surah}:${n.verse}';
      (map[key] ??= []).add(n);
    }
    for (final e in map.entries) {
      e.value.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    setState(() {
      _allBookmarks = bookmarks;
      _categories = categories;
      _notesByVerse = map;
      _loading = false;
    });
  }

  List<VerseBookmark> get _filteredBookmarks {
    if (_selectedCategoryId == null) return _allBookmarks;
    return _allBookmarks
        .where((b) => b.categoryId == _selectedCategoryId)
        .toList();
  }

  BookmarkCategory? _getCategoryFor(VerseBookmark bookmark) {
    if (bookmark.categoryId == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == bookmark.categoryId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filteredBookmarks;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('العلامات المرجعية'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.category_outlined),
                  tooltip: 'إدارة التصنيفات',
                  onPressed: _openCategoryManagement,
                ),
              ],
            ),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // ── Category filter chips ──
                      _buildCategoryFilter(colorScheme),

                      // ── Bookmarks list ──
                      Expanded(
                        child: filtered.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  return _buildBookmarkCard(
                                    context,
                                    filtered[index],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Category filter bar
  // ─────────────────────────────────────────────

  Widget _buildCategoryFilter(ColorScheme colorScheme) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1, // +1 for "All"
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" chip
            final isSelected = _selectedCategoryId == null;
            final count = _allBookmarks.length;
            return FilterChip(
              selected: isSelected,
              label: Text('الكل ($count)'),
              avatar: isSelected
                  ? null
                  : Icon(
                      Icons.bookmarks_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.onPrimaryContainer,
              onSelected: (_) {
                setState(() => _selectedCategoryId = null);
              },
            );
          }

          final cat = _categories[index - 1];
          final isSelected = _selectedCategoryId == cat.id;
          final count = _allBookmarks
              .where((b) => b.categoryId == cat.id)
              .length;

          return FilterChip(
            selected: isSelected,
            label: Text('${cat.title} ($count)'),
            avatar: isSelected
                ? null
                : CircleAvatar(backgroundColor: cat.color, radius: 7),
            selectedColor: cat.color.applyOpacity(0.25),
            checkmarkColor: cat.color,
            onSelected: (_) {
              setState(() => _selectedCategoryId = cat.id);
            },
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Empty state
  // ─────────────────────────────────────────────

  Widget _buildEmptyState() {
    final isFiltered = _selectedCategoryId != null;
    return Builder(
      builder: (context) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFiltered ? Icons.filter_list_off : Icons.bookmark_border,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.applyOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  isFiltered
                      ? 'لا توجد علامات في هذا التصنيف'
                      : 'لا توجد علامات مرجعية بعد',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isFiltered
                      ? 'جرّب اختيار تصنيف آخر أو عرض الكل'
                      : 'اضغط مطولاً على أي آية لإضافة علامة',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.applyOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Bookmark card
  // ─────────────────────────────────────────────

  Widget _buildBookmarkCard(BuildContext context, VerseBookmark bookmark) {
    final colorScheme = Theme.of(context).colorScheme;
    final category = _getCategoryFor(bookmark);
    final surahName = Quran.instance.getSurahNameArabic(bookmark.surah);
    final verseText = Quran.instance.getVerse(bookmark.surah, bookmark.verse);

    // Truncate verse text for preview
    final previewText = verseText.length > 100
        ? '${verseText.substring(0, 100)}...'
        : verseText;
    final verseKey = '${bookmark.surah}:${bookmark.verse}';
    final verseNotes = _notesByVerse[verseKey] ?? const [];
    final notesCount = verseNotes.length;
    final latestPreview = notesCount > 0 ? verseNotes.first.text : null;
    return Dismissible(
      key: Key(bookmark.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _deleteBookmark(bookmark),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _onBookmarkTap(bookmark),
          onSecondaryTapDown: (isMobilePlatform && !kIsWeb)
              ? null
              : (details) => _showBookmarkContextMenu(
                  context,
                  details.globalPosition,
                  bookmark,
                ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: surah info + category badge ──
                Row(
                  children: [
                    // Category color indicator
                    if (category != null)
                      Container(
                        width: 4,
                        height: 36,
                        margin: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          color: category.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                    // Surah + verse info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سورة $surahName',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'الآية ${getArabicNumber(bookmark.verse)}  •  '
                            'الصفحة ${getArabicNumber(bookmark.pageNumber)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontFamily:
                                      FontFamily.arabicNumbersFontFamily.name,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Category chip
                    if (category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: category.color.applyOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category.title,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: category.color,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),

                    // More options
                    if (isCompactWidth(context))
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        itemBuilder: (_) => _getBookmarkMenuItems(colorScheme),
                        onSelected: (value) => _onMenuAction(value, bookmark),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Verse preview ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    previewText,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: context.colorScheme.onSurface,
                      fontFamily: widget.settingsController.fontFamily.name,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // ── Note ──
                const SizedBox(height: 3),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: notesCount > 0 ? 3 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_note_outlined,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          notesCount == 0
                              ? 'لا توجد ملاحظات'
                              : 'ملاحظات: ${getArabicNumber(notesCount)}'
                                    '${latestPreview != null ? ' • ${latestPreview.replaceAll('\n', ' ')}' : ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            _openNotesForVerse(bookmark.surah, bookmark.verse),

                        child: Text(notesCount == 0 ? 'إضافة' : 'عرض'),
                      ),
                    ],
                  ),
                ),

                // ── Date ──
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _formatDate(bookmark.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.applyOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showBookmarkContextMenu(
    BuildContext context,
    Offset position,
    VerseBookmark bookmark,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        MediaQuery.widthOf(context) - position.dx,
        MediaQuery.heightOf(context) - position.dy,
      ),
      items: _getBookmarkMenuItems(colorScheme),
    );

    if (value != null && context.mounted) {
      _onMenuAction(value, bookmark);
    }
  }

  List<PopupMenuEntry<String>> _getBookmarkMenuItems(ColorScheme colorScheme) {
    return [
      const PopupMenuItem(
        value: 'change_category',
        child: Row(
          children: [
            Icon(Icons.category_outlined, size: 20),
            SizedBox(width: 8),
            Text('تغيير التصنيف'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'notes',
        child: Row(
          children: [
            Icon(Icons.edit_note_outlined, size: 20),
            SizedBox(width: 8),
            Text('الملاحظات'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
            const SizedBox(width: 8),
            Text('حذف', style: TextStyle(color: colorScheme.error)),
          ],
        ),
      ),
    ];
  }

  // ─────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────

  void _onBookmarkTap(VerseBookmark bookmark) {
    Navigator.pop(context);
    widget.onNavigateToPage(
      page: bookmark.pageNumber,
      surah: bookmark.surah,
      verse: bookmark.verse,
    );
  }

  void _onMenuAction(String action, VerseBookmark bookmark) {
    switch (action) {
      case 'notes':
        _openNotesSheet(bookmark.surah, bookmark.verse);
      case 'change_category':
        _changeCategory(bookmark);
      case 'delete':
        _deleteBookmark(bookmark);
    }
  }

  Future<void> _openNotesForVerse(int surah, int verse) async {
    final key = '$surah:$verse';
    final notes = _notesByVerse[key] ?? const <VerseNote>[];

    if (notes.isEmpty) {
      await _quickAddNote(surah, verse); // 1 tap add
      return;
    }

    await _openNotesSheet(surah, verse); // manage + add more notes
  }

  Future<void> _openNotesSheet(int surah, int verse) async {
    await showOverlay<void>(
      context,
      widget: Directionality(
        textDirection: TextDirection.rtl,
        child: VerseNotesManager(
          surah: surah,
          verse: verse,
          onChanged: _reloadAndNotify, // refresh cache + notify parent
        ),
      ),
      mobileConfig: const MobileOverlayConfig(
        isScrollControlled: true,
        showDragHandle: true,
      ),
      desktopConfig: const DesktopOverlayConfig(
        constraints: BoxConstraints(maxWidth: 500),
      ),
    );
  }

  Future<void> _quickAddNote(int surah, int verse) async {
    final res = await showEditNoteDialog(context); // your new dialog API
    if (res == null || res.action != NoteDialogAction.save) return;

    await _notesService.addNote(surah: surah, verse: verse, text: res.text!);

    await _reloadAndNotify(); // reload bookmarks + notes map
  }

  Future<void> _changeCategory(VerseBookmark bookmark) async {
    final result = await showOverlay<String>(
      context,
      widget: Column(
        mainAxisSize: .min,
        children: [
          Padding(
            padding: const .all(12),
            child: Row(
              children: [
                const Icon(Icons.bookmark, size: 20),
                const SizedBox(width: 8),
                Text(
                  'تغيير العلامة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!isCompactWidth(context)) const CloseButton(),
              ],
            ),
          ),
          Flexible(
            child: Padding(
              padding: const .fromLTRB(16, 0, 16, 16),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat.id == bookmark.categoryId;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cat.color,
                      radius: 14,
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                    title: Text(cat.title),
                    selected: isSelected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () => Navigator.pop(context, cat.id),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      mobileConfig: const MobileOverlayConfig(
        useSafeArea: true,
        showDragHandle: true,
        isScrollControlled: true,
      ),
      desktopConfig: const DesktopOverlayConfig(
        constraints: BoxConstraints(maxWidth: 500),
      ),
    );

    if (result == null || result == bookmark.categoryId) return;

    final updated = bookmark.copyWith(categoryId: () => result);
    await _bookmarkService.updateBookmark(updated);
    await _reloadAndNotify();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تغيير التصنيف ✓')));
    }
  }

  Future<bool?> _deleteBookmark(VerseBookmark bookmark) async {
    final confirmed = await _confirmDelete(context, bookmark);
    if (confirmed ?? false) {
      await _bookmarkService.removeBookmarkById(bookmark.id);
      await _reloadAndNotify();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تمت إزالة العلامة')));
      }
    }
    return confirmed ?? false;
  }

  Future<bool?> _confirmDelete(
    BuildContext context,
    VerseBookmark bookmark,
  ) async {
    final surahName = Quran.instance.getSurahNameArabic(bookmark.surah);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف العلامة'),
          content: Text(
            'هل تريد حذف العلامة من سورة $surahName، '
            'الآية ${getArabicNumber(bookmark.verse)}؟',
            style: TextStyle(
              fontSize: 16,
              fontFamily: FontFamily.arabicNumbersFontFamily.name,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCategoryManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const ManageCategoriesScreen()),
    );
    // Reload in case categories changed
    await _reloadAndNotify();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    if (diff.inDays < 30) return 'منذ ${(diff.inDays / 7).floor()} أسبوع';

    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
