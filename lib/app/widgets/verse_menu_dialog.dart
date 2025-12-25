import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:my_quran/quran/quran.dart';

import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/bookmark_service.dart';
import 'package:my_quran/app/utils.dart';

class VerseMenuDialog extends StatelessWidget {
  const VerseMenuDialog({required this.surah, required this.verse, super.key});
  final int surah;
  final Verse verse;

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Builder(
        builder: (context) {
          final bookmarkService = BookmarkService();
          bool isBookmarked = bookmarkService.isBookmarked(surah, verse.number);
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 340,
              minHeight: 200,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Scaffold(
                backgroundColor: Theme.of(context).colorScheme.surface,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                                fontWeight: FontWeight.w300,
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      Quran.instance.getSurahNameArabic(surah),
                                    ),
                                    const Text(' - '),
                                    const Text('الآية '),
                                    Text(
                                      getArabicNumber(verse.number),
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
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            verse.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              height: 2,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Actions
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            textButtonTheme: TextButtonThemeData(
                              style: ButtonStyle(
                                textStyle: const WidgetStatePropertyAll(
                                  TextStyle(fontSize: 16),
                                ),
                                foregroundColor: WidgetStatePropertyAll(
                                  Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildActionBtn(
                                icon: Icons.copy,
                                label: 'نسخ النص',
                                onTap: () => _copyVerse(context),
                              ),
                              StatefulBuilder(
                                builder: (context, setState) {
                                  return _buildActionBtn(
                                    icon: isBookmarked
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    label: isBookmarked
                                        ? 'إزالة العلامة'
                                        : 'إضافة علامة',
                                    onTap: () async {
                                      await _toggleBookmark(
                                        context,
                                        isBookmarked,
                                      );
                                      setState(() {
                                        isBookmarked = !isBookmarked;
                                      });
                                    },
                                    iconColor: isBookmarked
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return TextButton.icon(
      icon: Icon(icon, color: iconColor),
      label: Text(label),
      onPressed: () {
        onTap();
      },
    );
  }

  void _copyVerse(BuildContext context) {
    final surahName = Quran.instance.getSurahNameArabic(surah);
    final textToCopy =
        'سورة $surahName - الآية {${getArabicNumber(verse.number)}}\n'
        '"${Quran.instance.getVerseInPlainText(surah, verse.number)}"\n';
    Clipboard.setData(ClipboardData(text: textToCopy));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم النسخ إلى الحافظة')));
  }

  Future<void> _toggleBookmark(
    BuildContext context,
    bool isCurrentlyBookmarked,
  ) async {
    final bookmarkService = BookmarkService();
    final verseNum = verse.number;
    if (isCurrentlyBookmarked) {
      await bookmarkService.removeBookmarkByVerse(surah, verseNum);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تمت إزالة العلامة')));
      }
    } else {
      final bookmark = VerseBookmark(
        id:
            '${surah}_${verseNum}_'
            '${DateTime.now().millisecondsSinceEpoch}',
        surah: surah,
        verse: verseNum,
        pageNumber: Quran.instance.getPageNumber(surah, verseNum),
        createdAt: DateTime.now(),
      );
      await bookmarkService.addBookmark(bookmark);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تمت إضافة العلامة ✓')));
      }
    }
  }
}
