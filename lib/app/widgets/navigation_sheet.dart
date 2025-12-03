import 'dart:async';
import 'package:flutter/material.dart';

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

  // Debounce timers for each picker
  Timer? _pageDebounce;
  Timer? _surahDebounce;
  Timer? _juzDebounce;
  Timer? _verseDebounce;

  final Duration _debounceDuration = const Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();

    _currentPage = widget.initialPage;

    // Get initial position data
    final pageData = Quran.instance.getPageData(_currentPage);
    if (pageData.firstOrNull case {
      'surah': final int surahNum,
      'start': final int verseNum,
    }) {
      _currentSurah = surahNum;
      _currentVerse = verseNum;
      _currentJuz = Quran.instance.getJuzNumber(_currentSurah, _currentVerse);
    }

    // Initialize controllers
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

  @override
  void dispose() {
    _pageDebounce?.cancel();
    _surahDebounce?.cancel();
    _juzDebounce?.cancel();
    _verseDebounce?.cancel();

    _pageController.dispose();
    _surahController.dispose();
    _juzController.dispose();
    _verseController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_isUpdating) return;

    final pageNum = index + 1;
    setState(() {
      _currentPage = pageNum;
    });

    // Cancel previous debounce
    _pageDebounce?.cancel();

    // Start new debounce
    _pageDebounce = Timer(_debounceDuration, () {
      if (!mounted) return;
      _updateFromPage(pageNum);
    });
  }

  void _updateFromPage(int pageNum) {
    _isUpdating = true;

    final pageData = Quran.instance.getPageData(pageNum);
    if (pageData.firstOrNull case {
      'surah': final int surahNum,
      'start': final int verseNum,
    }) {
      final juzNum = Quran.instance.getJuzNumber(surahNum, verseNum);

      setState(() {
        _currentSurah = surahNum;
        _currentVerse = verseNum;
        _currentJuz = juzNum;
      });

      // Animate other controllers
      _surahController.animateToItem(
        surahNum - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _juzController.animateToItem(
        juzNum - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _verseController.animateToItem(
        verseNum - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    // Reset flag after a delay to allow animations to complete
    Future.delayed(const Duration(milliseconds: 400), () {
      _isUpdating = false;
    });
  }

  void _onSurahChanged(int index) {
    if (_isUpdating) return;

    final surahNum = index + 1;
    setState(() {
      _currentSurah = surahNum;
    });

    // Cancel previous debounce
    _surahDebounce?.cancel();

    // Start new debounce
    _surahDebounce = Timer(_debounceDuration, () {
      if (!mounted) return;
      _updateFromSurah(surahNum);
    });
  }

  void _updateFromSurah(int surahNum) {
    _isUpdating = true;

    setState(() {
      _currentVerse = 1; // Reset to first verse
    });

    // Get page for this surah
    final pageNum = Quran.instance.getPageNumber(surahNum, 1);
    final juzNum = Quran.instance.getJuzNumber(surahNum, 1);

    setState(() {
      _currentPage = pageNum;
      _currentJuz = juzNum;
    });

    // Animate other controllers
    _pageController.animateToItem(
      pageNum - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    _juzController.animateToItem(
      juzNum - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    _verseController.animateToItem(
      0, // First verse
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      _isUpdating = false;
    });
  }

  void _onJuzChanged(int index) {
    if (_isUpdating) return;

    final juzNum = index + 1;
    setState(() {
      _currentJuz = juzNum;
    });

    // Cancel previous debounce
    _juzDebounce?.cancel();

    // Start new debounce
    _juzDebounce = Timer(_debounceDuration, () {
      if (!mounted) return;
      _updateFromJuz(juzNum);
    });
  }

  void _updateFromJuz(int juzNum) {
    _isUpdating = true;

    // Get first verse of this juz
    final juzData = _getFirstVerseOfJuz(juzNum);
    final surahNum = juzData['surah']!;
    final verseNum = juzData['verse']!;
    final pageNum = Quran.instance.getPageNumber(surahNum, verseNum);

    setState(() {
      _currentSurah = surahNum;
      _currentVerse = verseNum;
      _currentPage = pageNum;
    });

    // Animate other controllers
    _pageController.animateToItem(
      pageNum - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    _surahController.animateToItem(
      surahNum - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    _verseController.animateToItem(
      verseNum - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      _isUpdating = false;
    });
  }

  void _onVerseChanged(int index) {
    if (_isUpdating) return;

    final verseNum = index + 1;
    final verseCount = Quran.instance.getVerseCount(_currentSurah);

    if (verseNum > verseCount) {
      return;
    }

    setState(() {
      _currentVerse = verseNum;
    });

    // Cancel previous debounce
    _verseDebounce?.cancel();

    // Start new debounce
    _verseDebounce = Timer(_debounceDuration, () {
      if (!mounted) return;
      _updateFromVerse(verseNum);
    });
  }

  void _updateFromVerse(int verseNum) {
    _isUpdating = true;

    // Get page for this verse
    final pageNum = Quran.instance.getPageNumber(_currentSurah, verseNum);
    final juzNum = Quran.instance.getJuzNumber(_currentSurah, verseNum);

    setState(() {
      _currentPage = pageNum;
      _currentJuz = juzNum;
    });

    // Animate other controllers
    _pageController.animateToItem(
      pageNum - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    _juzController.animateToItem(
      juzNum - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      _isUpdating = false;
    });
  }

  Map<String, int> _getFirstVerseOfJuz(int juzNum) {
    final firstJuzSurah = Quran.instance
        .getSurahAndVersesFromJuz(juzNum)
        .entries
        .first;
    return {'surah': firstJuzSurah.key, 'verse': firstJuzSurah.value.first};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          // Pickers
          Expanded(
            child: Row(
              children: [
                // Page picker
                Expanded(
                  child: _buildPicker(
                    controller: _pageController,
                    itemCount: Quran.totalPagesCount,
                    onSelectedItemChanged: _onPageChanged,
                    builder: (index) {
                      final pageNum = index + 1;
                      return _buildNumberWidget(
                        context,
                        pageNum,
                        pageNum == _currentPage,
                      );
                    },
                    label: 'الصفحة',
                  ),
                ),

                // Surah picker
                Expanded(
                  flex: 2,
                  child: _buildPicker(
                    controller: _surahController,
                    itemCount: 114,
                    onSelectedItemChanged: _onSurahChanged,
                    builder: (index) {
                      final surahNum = index + 1;
                      return Center(
                        child: Text(
                          Quran.instance.getSurahNameArabic(surahNum),
                          style: TextStyle(
                            fontSize: 22,
                            color: surahNum == _currentSurah
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                          textDirection: TextDirection.rtl,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                    label: 'السورة',
                  ),
                ),

                // Juz picker
                Expanded(
                  child: _buildPicker(
                    controller: _juzController,
                    itemCount: 30,
                    onSelectedItemChanged: _onJuzChanged,
                    builder: (index) {
                      final juzNum = index + 1;
                      return _buildNumberWidget(
                        context,
                        juzNum,
                        juzNum == _currentJuz,
                      );
                    },
                    label: 'الجزء',
                  ),
                ),

                // Verse picker
                Expanded(
                  child: _buildPicker(
                    controller: _verseController,
                    itemCount: Quran.instance.getVerseCount(_currentSurah),
                    onSelectedItemChanged: _onVerseChanged,
                    builder: (index) {
                      final verseNum = index + 1;
                      return _buildNumberWidget(
                        context,
                        verseNum,
                        verseNum == _currentVerse,
                      );
                    },
                    label: 'الآية',
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
    );
  }

  Widget _buildNumberWidget(BuildContext context, int number, bool isCurrent) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      _toArabicNumber(number),
      style: TextStyle(
        fontSize: 22,
        fontFamily: FontFamily.defaultFontFamily.name,
        color: isCurrent ? colorScheme.primary : colorScheme.onSurface,
        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onSelectedItemChanged,
    required Widget Function(int index) builder,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Stack(
            children: [
              // Selection indicator
              Center(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Picker
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 40,
                perspective: 0.0000004,
                diameterRatio: 1.2,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: onSelectedItemChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    if (index < 0 || index >= itemCount) return null;
                    return builder(index);
                  },
                  childCount: itemCount,
                ),
              ),
            ],
          ),
        ),
      ],
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
