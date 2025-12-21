import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/utils.dart';
import 'package:my_quran/quran/quran.dart';

class PinnedHeader extends StatelessWidget {
  const PinnedHeader({
    required this.currentPositionNotifier,
    required this.goToPage,
    required this.glassDecoration,
    required this.infoHeight,
    required this.statusBarHeight,
    required this.appBarHeight,
    super.key,
  });

  final ValueNotifier<ReadingPosition> currentPositionNotifier;
  final void Function(int page, {int? highlightSurah, int? highlightVerse})
  goToPage;
  final BoxDecoration glassDecoration;
  final double infoHeight;
  final double statusBarHeight;
  final double appBarHeight;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: statusBarHeight + appBarHeight, // Push down by AppBar height
      left: 0,
      right: 0,
      height: infoHeight,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DefaultTextStyle(
            style: TextStyle(
              fontFamily: FontFamily.arabicNumbersFontFamily.name,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            child: Container(
              decoration: glassDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ValueListenableBuilder<ReadingPosition>(
                valueListenable: currentPositionNotifier,
                builder: (context, position, _) {
                  final surahName = Quran.instance.getSurahNameArabic(
                    position.surahNumber,
                  );
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => onSurahTapped(context),
                            child: Text(
                              '${getArabicNumber(position.surahNumber)} - '
                              '$surahName',
                            ),
                          ),
                          GestureDetector(
                            onTap: () => onJuzTapped(context),
                            child: Text(
                              'جزء ${getArabicNumber(position.juzNumber)}',
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => onPageNumberTapped(context),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              getArabicNumber(position.pageNumber),
                              key: ValueKey(position.pageNumber),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onJuzTapped(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('أدخل رقم الجزء'),
        contentPadding: const EdgeInsets.all(24),
        children: [
          TextField(
            maxLength: 2,
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  required maxLength,
                }) => const SizedBox.shrink(),
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 18),
            onSubmitted: (value) {
              final juz = int.tryParse(value);
              if (juz is! int || juz < 1 || juz > 30) {
                return;
              }
              final firstSurahOfJuz = Quran.instance
                  .getSurahAndVersesFromJuz(juz)
                  .entries
                  .first;
              final surahNumber = firstSurahOfJuz.key;
              final verseNumber = firstSurahOfJuz.value.first;
              Navigator.pop(context);
              goToPage(
                Quran.instance.getPageNumber(surahNumber, verseNumber),
                highlightSurah: surahNumber,
                highlightVerse: verseNumber,
              );
            },
          ),
        ],
      ),
    );
  }

  void onPageNumberTapped(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('أدخل رقم الصفحة'),
        contentPadding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 18),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'الرجاء إدخال رقم صفحة';
              }

              final page = int.tryParse(value!);
              if (page is! int || page < 1 || page > Quran.totalPagesCount) {
                return 'الرجاء إدخال رقم صفحة صحيح';
              }
              return null;
            },

            onFieldSubmitted: (value) {
              final page = int.tryParse(value);
              if (page is! int || page < 1 || page > Quran.totalPagesCount) {
                return;
              }

              Navigator.pop(context);
              goToPage(page);
            },
          ),
        ],
      ),
    );
  }

  void onSurahTapped(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => _SearchSurahDialog(
        onSurahTapped: (surahNumber) {
          Navigator.pop(context);
          final pageNumber = Quran.instance.getPageNumber(surahNumber, 1);
          goToPage(pageNumber, highlightSurah: surahNumber, highlightVerse: 1);
        },
      ),
    );
  }
}

class _SearchSurahDialog extends StatefulWidget {
  const _SearchSurahDialog({required this.onSurahTapped});
  final void Function(int surahNumber) onSurahTapped;
  @override
  State<_SearchSurahDialog> createState() => _SearchSurahDialogState();
}

class _SearchSurahDialogState extends State<_SearchSurahDialog> {
  late final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    return SimpleDialog(
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      children: [
        TextField(controller: searchController, autofocus: true),
        SizedBox(
          width: screen.width * .8,
          height: screen.height * .5,
          child: ValueListenableBuilder(
            valueListenable: searchController,
            builder: (context, value, _) {
              final items = Quran.surahNames
                  .where(
                    (e) =>
                        e.arabic.contains(value.text) ||
                        e.english.toLowerCase().contains(
                          value.text.toLowerCase(),
                        ),
                  )
                  .toList();
              if (items.isEmpty) {
                return const Center(child: Text('لا توجد نتائج...'));
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => ListTile(
                  title: GestureDetector(
                    onTap: () => widget.onSurahTapped(items[index].number),
                    child: Text(
                      '${items[index].arabic} - ${items[index].english}',
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
