import 'package:flutter/material.dart';
import 'package:my_quran/app/pages/bookmark_categories_page.dart';
import 'package:my_quran/app/settings_controller.dart';
import 'package:my_quran/app/widgets/edit_note_dialog.dart';

import 'package:my_quran/quran/quran.dart';

import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/bookmark_service.dart';
import 'package:my_quran/app/utils.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({
    required this.settingsController,
    required this.onNavigateToPage,
    super.key,
  });
  final void Function({
    required int page,
    required int surah,
    required int verse,
  })
  onNavigateToPage;
  final SettingsController settingsController;

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final _bookmarkService = BookmarkService();

  List<VerseBookmark> _allBookmarks = [];
  List<BookmarkCategory> _categories = [];
  String? _selectedCategoryId; // null = show all
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bookmarks = await _bookmarkService.getBookmarks();
    final categories = await _bookmarkService.getCategories();

    // Sort by creation date, newest first
    bookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _allBookmarks = bookmarks;
      _categories = categories;
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

    return Dismissible(
      key: Key(bookmark.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, bookmark),
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
                                ?.copyWith(fontWeight: FontWeight.bold),
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
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      itemBuilder: (_) => [
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
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'حذف',
                                style: TextStyle(color: colorScheme.error),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                    color: colorScheme.surfaceContainerHighest.applyOpacity(
                      0.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    previewText,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: colorScheme.onSurface,
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
                    vertical: (bookmark.note?.isEmpty ?? true) ? 0 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.applyOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (bookmark.note?.isNotEmpty ?? false)
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              bookmark.note!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_note_outlined),
                        label: (bookmark.note?.isNotEmpty ?? false)
                            ? const Text('تعديل')
                            : const Text('تسجيل ملاحظة'),
                        onPressed: () => _onMenuAction('edit_note', bookmark),
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
      case 'edit_note':
        _editNote(bookmark);
      case 'change_category':
        _changeCategory(bookmark);
      case 'delete':
        _deleteBookmark(bookmark);
    }
  }

  Future<void> _editNote(VerseBookmark bookmark) async {
    final result = await showEditNoteDialog(context, bookmark);

    if (result == null) return;

    final updatedNote = result.trim();
    final updated = bookmark.copyWith(note: () => updatedNote);
    await _bookmarkService.updateBookmark(updated);
    await _load();
  }

  Future<void> _changeCategory(VerseBookmark bookmark) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تغيير التصنيف'),
            content: SizedBox(
              width: double.maxFinite,
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null || result == bookmark.categoryId) return;

    final updated = bookmark.copyWith(categoryId: () => result);
    await _bookmarkService.updateBookmark(updated);
    await _load();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تغيير التصنيف ✓')));
    }
  }

  Future<void> _deleteBookmark(VerseBookmark bookmark) async {
    final confirmed = await _confirmDelete(context, bookmark);
    if (confirmed ?? false) {
      await _bookmarkService.removeBookmarkById(bookmark.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تمت إزالة العلامة')));
      }
    }
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
      MaterialPageRoute<void>(
        builder: (_) => ManageCategoriesScreen(
          settingsController: widget.settingsController,
        ),
      ),
    );
    // Reload in case categories changed
    await _load();
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
