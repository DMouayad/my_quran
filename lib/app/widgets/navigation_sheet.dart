import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:my_quran/app/models.dart';
import 'package:my_quran/quran/quran.dart';

class QuranNavigationBottomSheet extends StatefulWidget {
  const QuranNavigationBottomSheet({
    required this.initialPage,
    required this.onNavigate,
    super.key,
  });

  final int initialPage;
  final void Function({
    required int page,
    required int surah,
    required int verse,
  })
  onNavigate;

  @override
  State<QuranNavigationBottomSheet> createState() =>
      _QuranNavigationBottomSheetState();
}

class _QuranNavigationBottomSheetState
    extends State<QuranNavigationBottomSheet> {
  late FixedExtentScrollController _pageController;
  late FixedExtentScrollController _surahController;
  late FixedExtentScrollController _juzController;
  late FixedExtentScrollController _verseController;

  int _currentPage = 1;
  int _currentSurah = 1;
  int _currentJuz = 1;
  int _currentVerse = 1;

  bool _isUpdating = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _initDataFromPage(_currentPage);

    _pageController = FixedExtentScrollController(
      initialItem: _currentPage - 1,
    );
    _surahController = FixedExtentScrollController(
      initialItem: _currentSurah - 1,
    );
    _juzController = FixedExtentScrollController(initialItem: _currentJuz - 1);
    _verseController = FixedExtentScrollController(
      initialItem: _currentVerse - 1,
    );
  }

  void _initDataFromPage(int page) {
    final pageData = Quran.instance.getPageData(page);
    if (pageData.isNotEmpty) {
      final firstEntry = pageData.first;
      _currentSurah = firstEntry['surah']!;
      _currentVerse = firstEntry['start']!;
      _currentJuz = Quran.instance.getJuzNumber(_currentSurah, _currentVerse);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pageController.dispose();
    _surahController.dispose();
    _juzController.dispose();
    _verseController.dispose();
    super.dispose();
  }

  // --- LOGIC (Same as before, just keeping it sync) ---

  void _triggerUpdate(VoidCallback updateFn) {
    if (_isUpdating) return;

    HapticFeedback.selectionClick(); // Subtle click
    setState(() {}); // Rebuild to update highlight text color immediately

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _isUpdating = true);

      updateFn();

      // Unlock after animations roughly finish
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _isUpdating = false);
      });
    });
  }

  void _onPageChanged(int index) {
    final page = index + 1;
    _currentPage = page;
    _triggerUpdate(() {
      _initDataFromPage(page);
      _animateAll();
    });
  }

  void _onSurahChanged(int index) {
    final surah = index + 1;
    _currentSurah = surah;
    _triggerUpdate(() {
      _currentVerse = 1;
      _currentPage = Quran.instance.getPageNumber(surah, 1);
      _currentJuz = Quran.instance.getJuzNumber(surah, 1);
      _animateAll();
    });
  }

  void _onJuzChanged(int index) {
    final juz = index + 1;
    _currentJuz = juz;
    _triggerUpdate(() {
      final surahs = Quran.instance.getSurahAndVersesFromJuz(juz);
      _currentSurah = surahs.keys.first;
      _currentVerse = surahs[_currentSurah]!.first;
      _currentPage = Quran.instance.getPageNumber(_currentSurah, _currentVerse);
      _animateAll();
    });
  }

  void _onVerseChanged(int index) {
    final verse = index + 1;
    _currentVerse = verse;
    _triggerUpdate(() {
      _currentPage = Quran.instance.getPageNumber(_currentSurah, verse);
      _currentJuz = Quran.instance.getJuzNumber(_currentSurah, verse);
      _animateAll(skipVerse: true);
    });
  }

  void _animateAll({bool skipVerse = false}) {
    _pageController.jumpToItem(_currentPage - 1);
    _surahController.jumpToItem(_currentSurah - 1);
    _juzController.jumpToItem(_currentJuz - 1);
    if (!skipVerse) {
      final max = Quran.instance.getVerseCount(_currentSurah);
      _verseController.jumpToItem((_currentVerse - 1).clamp(0, max - 1));
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTextStyle(
      style: TextStyle(fontFamily: FontFamily.hafs.name),
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Minimal Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // --- PICKERS AREA ---
              Expanded(
                child: Stack(
                  children: [
                    // 1. The Highlight Bar (Behind the selected item)
                    Center(
                      child: Container(
                        height: 44,
                        margin: const EdgeInsets.only(top: 26),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                        ),
                      ),
                    ),

                    // 2. The Flat Pickers
                    Row(
                      children: [
                        Expanded(
                          child: _buildFlatWheel(
                            controller: _pageController,
                            count: Quran.totalPagesCount,
                            label: 'الصفحة',
                            onChanged: _onPageChanged,
                            itemBuilder: (i) => _buildItem(i + 1),
                          ),
                        ),
                        Expanded(
                          flex: 2, // Surah gets more space
                          child: _buildFlatWheel(
                            controller: _surahController,
                            count: Quran.totalSurahCount,
                            label: 'السورة',
                            onChanged: _onSurahChanged,
                            itemBuilder: (i) => Center(
                              child: Text(
                                Quran.instance.getSurahNameArabic(i + 1),
                                style: TextStyle(
                                  fontSize: 20,
                                  color: (i + 1) == _currentSurah
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                  fontWeight: (i + 1) == _currentSurah
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildFlatWheel(
                            controller: _juzController,
                            count: Quran.totalJuzCount,
                            label: 'الجزء',
                            onChanged: _onJuzChanged,
                            itemBuilder: (i) => _buildItem(i + 1),
                          ),
                        ),
                        Expanded(
                          child: _buildFlatWheel(
                            controller: _verseController,
                            count: Quran.instance.getVerseCount(_currentSurah),
                            label: 'الآية',
                            onChanged: _onVerseChanged,
                            itemBuilder: (i) => _buildItem(i + 1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- BOTTOM ACTIONS ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () {
                          widget.onNavigate(
                            page: _currentPage,
                            surah: _currentSurah,
                            verse: _currentVerse,
                          );
                          Navigator.pop(context);
                        },
                        child: const Text('انتقال'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlatWheel({
    required FixedExtentScrollController controller,
    required int count,
    required String label,
    required ValueChanged<int> onChanged,
    required Widget Function(int) itemBuilder,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 44, // Matches highlight bar height
            physics: const FixedExtentScrollPhysics(),
            changeReportingBehavior: ChangeReportingBehavior.onScrollEnd,
            diameterRatio: 100, // Huge diameter = appears straight
            perspective: 0.0001, // Near zero perspective = no 3D tilt
            // -----------------------
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index >= count) return null;
                return itemBuilder(index);
              },
              childCount: count,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(int number) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      _toArabicNumber(number),
      style: TextStyle(
        fontSize: 20,
        color: colorScheme.onSurface,
        fontFamily: FontFamily.arabicNumbersFontFamily.name,
      ),
    );
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
