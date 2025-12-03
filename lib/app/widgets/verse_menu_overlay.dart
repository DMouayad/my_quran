import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:my_quran/quran/quran.dart';

import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/bookmark_service.dart';

class VerseMenuOverlay extends StatefulWidget {
  const VerseMenuOverlay({
    required this.surah,
    required this.verse,
    required this.onDismiss,
    this.onBookmarkToggled,
    super.key,
  });
  final int surah;
  final Verse verse;
  final VoidCallback onDismiss;
  final VoidCallback? onBookmarkToggled;

  @override
  State<VerseMenuOverlay> createState() => _VerseMenuOverlayState();
}

class _VerseMenuOverlayState extends State<VerseMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.ease,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkService = BookmarkService();
    final isBookmarked = bookmarkService.isBookmarked(
      widget.surah,
      widget.verse.number,
    );

    return GestureDetector(
      onTap: _dismiss,
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(
        color: Colors.black26,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent dismissal when tapping menu
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.surfaceContainer,
                              Theme.of(context).colorScheme.primaryContainer,
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.menu_book,
                                    size: 20,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        Quran.instance.getSurahNameArabic(
                                          widget.surah,
                                        ),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                      const Text(' - '),
                                      Text(
                                        'الآية ${_toArabicNumber(widget.verse.number)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          fontFamily: FontFamily
                                              .arabicNumbersFontFamily
                                              .name,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: _dismiss,
                                ),
                              ],
                            ),
                            Text(
                              widget.verse.text,
                              style: TextStyle(
                                fontSize: 18,
                                height: 1.8,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Actions
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMenuTile(
                              icon: Icons.copy,
                              label: 'نسخ النص',
                              onTap: _copyVerse,
                            ),
                            _buildMenuTile(
                              icon: isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              label: isBookmarked
                                  ? 'إزالة العلامة'
                                  : 'إضافة علامة',
                              onTap: () => _toggleBookmark(isBookmarked),
                              iconColor: isBookmarked
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return SizedBox(
      width: 150,
      child: ListTile(
        leading: Icon(icon, size: 22, color: iconColor),
        title: Text(label, style: const TextStyle(fontSize: 15)),
        onTap: () {
          onTap();
          _dismiss();
        },
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _copyVerse() {
    final surahName = Quran.instance.getSurahName(widget.surah);
    final textToCopy = '${widget.verse.text}\n\n[$surahName: ${widget.verse}]';
    Clipboard.setData(ClipboardData(text: textToCopy));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم النسخ إلى الحافظة')));
  }

  Future<void> _toggleBookmark(bool isCurrentlyBookmarked) async {
    final bookmarkService = BookmarkService();
    final verseNum = widget.verse.number;
    if (isCurrentlyBookmarked) {
      await bookmarkService.removeBookmarkByVerse(widget.surah, verseNum);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تمت إزالة العلامة')));
      }
    } else {
      final bookmark = VerseBookmark(
        id: '${widget.surah}_${verseNum}_${DateTime.now().millisecondsSinceEpoch}',
        surah: widget.surah,
        verse: verseNum,
        pageNumber: Quran.instance.getPageNumber(widget.surah, verseNum),
        verseText: widget.verse.text,
        createdAt: DateTime.now(),
      );
      await bookmarkService.addBookmark(bookmark);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تمت إضافة العلامة ✓')));
      }
    }

    widget.onBookmarkToggled?.call();
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
