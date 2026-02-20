import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_quran/app/widgets/edit_note_dialog.dart';

import 'package:my_quran/quran/quran.dart';

import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/bookmark_service.dart';
import 'package:my_quran/app/utils.dart';

class VerseMenuDialog extends StatefulWidget {
  const VerseMenuDialog({required this.surah, required this.verse, super.key});
  final int surah;
  final Verse verse;

  @override
  State<VerseMenuDialog> createState() => _VerseMenuDialogState();
}

class _VerseMenuDialogState extends State<VerseMenuDialog> {
  late final bookmarkService = BookmarkService();
  late bool isBookmarked = bookmarkService.isBookmarked(
    widget.surah,
    widget.verse.number,
  );
  late VerseBookmark? bookmark = bookmarkService.getBookmarkFor(
    widget.surah,
    widget.verse.number,
  );
  late final List<BookmarkCategory> categories = bookmarkService
      .getCategoriesSync();

  BookmarkCategory? currentCategory;

  @override
  void initState() {
    super.initState();
    if (isBookmarked && bookmark?.categoryId != null) {
      try {
        currentCategory = categories.firstWhere(
          (c) => c.id == bookmark!.categoryId,
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Builder(
        builder: (context) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 340,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Scaffold(
                backgroundColor: Theme.of(context).colorScheme.surface,
                // ── Fixed bottom actions ──
                bottomNavigationBar: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      // ── Copy ──
                      _ActionButton(
                        icon: Icons.copy,
                        label: 'نسخ',
                        onTap: () => _copyVerse(context),
                      ),

                      // ── Bookmark with color picker ──
                      _BookmarkActionButton(
                        isBookmarked: isBookmarked,
                        currentCategory: currentCategory,
                        categories: categories,
                        onCategorySelected: (cat) async {
                          if (isBookmarked) {
                            final updated = bookmark!.copyWith(
                              categoryId: () => cat.id,
                            );
                            await bookmarkService.updateBookmark(updated);
                            setState(() {
                              bookmark = updated;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'تم النقل إلى "${cat.title}" ✓',
                                  ),
                                ),
                              );
                            }
                          } else {
                            final newBookmark = VerseBookmark(
                              id:
                                  '${widget.surah}_${widget.verse.number}_'
                                  '${DateTime.now().millisecondsSinceEpoch}',
                              surah: widget.surah,
                              verse: widget.verse.number,
                              pageNumber: Quran.instance.getPageNumber(
                                widget.surah,
                                widget.verse.number,
                              ),
                              createdAt: DateTime.now(),
                              categoryId: cat.id,
                            );
                            await bookmarkService.addBookmark(newBookmark);
                            setState(() {
                              isBookmarked = true;
                              bookmark = newBookmark;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تمت إضافة العلامة ✓'),
                                ),
                              );
                            }
                          }
                        },
                        onRemove: () async {
                          await bookmarkService.removeBookmarkByVerse(
                            widget.surah,
                            widget.verse.number,
                          );
                          setState(() {
                            isBookmarked = false;
                            bookmark = null;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تمت إزالة العلامة'),
                              ),
                            );
                          }
                        },
                      ),

                      _ActionButton(
                        iconColor: (bookmark?.note?.isNotEmpty ?? false)
                            ? context.colorScheme.primary
                            : context.colorScheme.onSurfaceVariant,
                        icon: (bookmark?.note?.isNotEmpty ?? false)
                            ? Icons.edit_note
                            : Icons.note_add_outlined,

                        label: 'ملاحظة',
                        onTap: () async {
                          final updated = await _showEditNoteDialog(
                            context,
                            bookmark,
                            categories,
                          );

                          if (updated != null) {
                            if (!isBookmarked) {
                              await bookmarkService.addBookmark(updated);
                              final newCategory = updated.categoryId != null
                                  ? await bookmarkService.getCategoryById(
                                      updated.categoryId!,
                                    )
                                  : categories.first;
                              setState(() {
                                isBookmarked = true;
                                currentCategory = newCategory;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تمت إضافة العلامة ✓'),
                                  ),
                                );
                              }
                            }
                            setState(() {
                              bookmark = updated;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // ── Body: header + centered verse ──
                body: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ──
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          const SizedBox(width: 18),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.menu_book,
                              size: 18,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DefaultTextStyle(
                              style: TextStyle(
                                fontFamily: FontFamily.rustam.name,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    Quran.instance.getSurahNameArabic(
                                      widget.surah,
                                    ),
                                  ),
                                  const Text(' - '),
                                  const Text('الآية '),
                                  Text(
                                    getArabicNumber(widget.verse.number),
                                    style: TextStyle(
                                      fontFamily: FontFamily
                                          .arabicNumbersFontFamily
                                          .name,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),

                    // ── Verse text (centered, scrollable) ──
                    Flexible(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            widget.verse.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              height: 2,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (bookmark?.note?.isNotEmpty ?? false)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.colorScheme.tertiaryContainer
                              .applyOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          bookmark!.note!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _copyVerse(BuildContext context) {
    final surahName = Quran.instance.getSurahNameArabic(widget.surah);
    final textToCopy =
        'سورة $surahName - الآية {${getArabicNumber(widget.verse.number)}}\n'
        '"${Quran.instance.getVerseInPlainText(widget.surah, widget.verse.number)}"\n';
    Clipboard.setData(ClipboardData(text: textToCopy));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم النسخ إلى الحافظة')));
  }

  Future<VerseBookmark?> _showEditNoteDialog(
    BuildContext context,
    VerseBookmark? bookmark,
    List<BookmarkCategory> categories,
  ) async {
    final result = await showEditNoteDialog(context, bookmark);

    if (result == null) return null;

    final updatedNote = result == '\x00' ? null : result.trim();

    final VerseBookmark updated =
        bookmark?.copyWith(note: () => updatedNote) ??
        VerseBookmark(
          id:
              '${widget.surah}_${widget.verse.number}_'
              '${DateTime.now().millisecondsSinceEpoch}',
          surah: widget.surah,
          verse: widget.verse.number,
          pageNumber: Quran.instance.getPageNumber(
            widget.surah,
            widget.verse.number,
          ),
          createdAt: DateTime.now(),
          categoryId: categories.firstOrNull?.id,
          note: updatedNote,
        );

    return updated;
  }
}

// ─────────────────────────────────────────────────────────
// Compact action button
// ─────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Bookmark button with color picker popup
// ─────────────────────────────────────────────────────────

class _BookmarkActionButton extends StatelessWidget {
  const _BookmarkActionButton({
    required this.isBookmarked,
    required this.currentCategory,
    required this.categories,
    required this.onCategorySelected,
    required this.onRemove,
  });

  final bool isBookmarked;
  final BookmarkCategory? currentCategory;
  final List<BookmarkCategory> categories;
  final ValueChanged<BookmarkCategory> onCategorySelected;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final color =
        currentCategory?.color ?? Theme.of(context).colorScheme.onSurface;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showColorPicker(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                size: 22,
                color: isBookmarked ? color : null,
              ),
              const SizedBox(height: 4),
              Text(
                isBookmarked ? 'تعديل' : 'علامة',
                style: TextStyle(
                  fontSize: 11,
                  color: isBookmarked
                      ? color
                      : Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Total menu items height for positioning above the button
    final itemCount = categories.length + (isBookmarked ? 2 : 0);
    final menuHeight = itemCount * 44.0 + 16.0; // padding

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy - menuHeight,
        offset.dx + size.width,
        offset.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: [
        ...categories.map((cat) {
          final isSelected = isBookmarked && currentCategory?.id == cat.id;
          return PopupMenuItem<String>(
            value: cat.id,
            height: 44,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: cat.color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 2,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cat.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          );
        }),
        if (isBookmarked) ...[
          const PopupMenuItem<String>(
            enabled: false,
            height: 8,
            child: Divider(height: 1),
          ),
          PopupMenuItem<String>(
            value: '__remove__',
            height: 44,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  Icon(
                    Icons.bookmark_remove_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'إزالة العلامة',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ).then((value) {
      if (value == null) return;
      if (value == '__remove__') {
        onRemove();
        return;
      }
      try {
        final cat = categories.firstWhere((c) => c.id == value);
        if (isBookmarked && currentCategory?.id == cat.id) return;
        onCategorySelected(cat);
      } catch (_) {}
    });
  }
}
