// ignore_for_file: lines_longer_than_80_chars (will refactor soon)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:my_quran/app/pages/bookmarks_screen.dart';
import 'package:my_quran/app/widgets/settings_sheet.dart';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:my_quran/app/quran_page_text_cache.dart';
import 'package:my_quran/app/settings_controller.dart';
import 'package:my_quran/app/font_size_controller.dart';
import 'package:my_quran/app/services/reading_position_service.dart';
import 'package:my_quran/app/utils.dart';
import 'package:my_quran/app/quran_helpers.dart';
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/widgets/navigation_sheet.dart';
import 'package:my_quran/app/widgets/verse_menu_dialog.dart';
import 'package:my_quran/app/widgets/search_sheet.dart';
import 'package:my_quran/app/widgets/pinned_header.dart';
import 'package:my_quran/quran/quran.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.settingsController,
    this.initialPosition,
    super.key,
  });

  final ReadingPosition? initialPosition;
  final SettingsController settingsController;

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final ValueNotifier<({int surah, int verse})?> _highlightedVerseNotifier;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  late final ValueNotifier<ReadingPosition> _currentPositionNotifier;
  late final _pageController = PageController(
    initialPage: widget.initialPosition?.pageNumber ?? 0,
  );

  /// Used to keep track of current scroll mode
  late bool _isHorizontalScrolling =
      widget.settingsController.isHorizontalScrolling;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _highlightedVerseNotifier = ValueNotifier(null);
    Quran.data.addListener(_onQuranDataChanged);
    _currentPositionNotifier = ValueNotifier(
      widget.initialPosition ??
          const ReadingPosition(
            pageNumber: 1,
            surahNumber: 1,
            verseNumber: 1,
            juzNumber: 1,
          ),
    );

    _itemPositionsListener.itemPositions.addListener(_onScrollUpdate);
    widget.settingsController.addListener(_onScrollingModeChanged);
  }

  @override
  void dispose() {
    _highlightedVerseNotifier.dispose();
    _pageController.dispose();
    ReadingPositionService.savePosition(_currentPositionNotifier.value);
    _itemPositionsListener.itemPositions.removeListener(_onScrollUpdate);
    WidgetsBinding.instance.removeObserver(this);
    _currentPositionNotifier.dispose();
    Quran.data.removeListener(_onQuranDataChanged);
    widget.settingsController.removeListener(_onScrollingModeChanged);
    super.dispose();
  }

  void _onScrollingModeChanged() {
    final newIsHorizontalScrolling =
        widget.settingsController.isHorizontalScrolling;
    if (!newIsHorizontalScrolling && _isHorizontalScrolling) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _itemScrollController.jumpTo(
          index: _currentPositionNotifier.value.pageNumber - 1,
        );
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          Future.delayed(const Duration(milliseconds: 200), () {
            _pageController.jumpToPage(
              _currentPositionNotifier.value.pageNumber - 1,
            );
          });
        }
      });
    }

    _isHorizontalScrolling = widget.settingsController.isHorizontalScrolling;
  }

  void _onQuranDataChanged() {
    QuranPageTextCache.instance.invalidateForNewQuranData();
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ReadingPositionService.savePosition(_currentPositionNotifier.value);
    }
  }

  void _onScrollUpdate() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    ItemPosition? bestCandidate;

    for (final pos in positions) {
      if (bestCandidate == null || pos.index < bestCandidate.index) {
        if (pos.itemTrailingEdge > 0.15) {
          bestCandidate = pos;
        }
      }
    }

    if (bestCandidate == null) {
      // Fallback: find minimum index
      int minIndex = positions.first.index;
      for (final pos in positions) {
        if (pos.index < minIndex) minIndex = pos.index;
      }
      bestCandidate = positions.firstWhere((p) => p.index == minIndex);
    }

    final newPageNumber = bestCandidate.index + 1;

    // Only update state if changed to prevent rebuilds
    if (_currentPositionNotifier.value.pageNumber != newPageNumber) {
      _updateReadingPosition(newPageNumber);
    }
  }

  void _updateReadingPosition(int pageNumber) {
    final pageData = Quran.instance.getPageData(pageNumber);
    if (pageData.isNotEmpty) {
      final firstSurah = pageData.first;
      final surahNum = firstSurah['surah']!;
      final verseNum = firstSurah['start']!;
      final juz = Quran.instance.getJuzNumber(surahNum, verseNum);
      _currentPositionNotifier.value = ReadingPosition(
        pageNumber: pageNumber,
        surahNumber: surahNum,
        verseNumber: verseNum,
        juzNumber: juz,
      );
    }
  }

  Future<void> _jumpToPage(
    int pageNumber, {
    int? highlightSurah,
    int? highlightVerse,
  }) async {
    // 1. Set Highlight State
    if (highlightSurah != null && highlightVerse != null) {
      _highlightedVerseNotifier.value = (
        surah: highlightSurah,
        verse: highlightVerse,
      );
    } else {
      _highlightedVerseNotifier.value = null;
    }

    _updateReadingPosition(pageNumber);

    final index = (pageNumber - 1).clamp(0, Quran.totalPagesCount - 1);

    // 2. Calculate Alignment
    double alignment = 0;
    if (highlightSurah != null && highlightVerse != null) {
      alignment = getVerseAlignmentOnPage(
        pageNumber: pageNumber,
        highlightSurah: highlightSurah,
        highlightVerse: highlightVerse,
      );
    }

    // 3. Jump to new page
    if (widget.settingsController.isHorizontalScrolling) {
      _pageController.jumpToPage(index);
    } else {
      _itemScrollController.jumpTo(index: index, alignment: alignment);
    }
  }

  // Helper to handle manual tap selection
  void _onVerseTapped(int surah, int verse) {
    final curr = _highlightedVerseNotifier.value;
    if (curr?.surah == surah && curr?.verse == verse) {
      _highlightedVerseNotifier.value = null;
    } else {
      _highlightedVerseNotifier.value = (surah: surah, verse: verse);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Heights
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double appBarHeight = kToolbarHeight; // Standard 56.0
    const double infoHeaderHeight = 38; // Height of our Surah/Page strip

    // Total height obscuring the top
    final double totalTopHeaderHeight =
        statusBarHeight + appBarHeight + infoHeaderHeight;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appBarDecoration = BoxDecoration(
      color: isDarkMode && widget.settingsController.useTrueBlackBgColor
          ? Colors.black
          : Theme.of(context).colorScheme.surfaceContainerLow,
      border: Border(
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.applyOpacity(0.3),
        ),
      ),
    );

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.primary,
        elevation: 4,
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          constraints: const BoxConstraints(maxHeight: 600),
          builder: (_) => QuranNavigationBottomSheet(
            initialPage: _currentPositionNotifier.value.pageNumber,
            onNavigate:
                ({required int page, required int surah, required int verse}) =>
                    _jumpToPage(
                      page,
                      highlightSurah: surah,
                      highlightVerse: verse,
                    ),
          ),
        ),
        child: Icon(Icons.menu_book_outlined, color: colorScheme.primary),
      ),
      // --- 1. The Glass App Bar ---
      appBar: AppBar(
        systemOverlayStyle: isDarkMode
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleSpacing: 4,
        title: Row(
          spacing: 5,
          children: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                showDragHandle: true,
                builder: (_) => QuranSearchBottomSheet(
                  onNavigateToPage: (int page, {int? surah, int? verse}) =>
                      _jumpToPage(
                        page,
                        highlightSurah: surah,
                        highlightVerse: verse,
                      ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => BookmarksScreen(
                      settingsController: widget.settingsController,
                      onNavigateToPage:
                          ({
                            required int page,
                            required int surah,
                            required int verse,
                          }) => _jumpToPage(
                            page,
                            highlightSurah: surah,
                            highlightVerse: verse,
                          ),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: Text(
                'قرآني',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: context.colorScheme.secondary,
                  fontFamily: FontFamily.rustam.name,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(decoration: appBarDecoration),
        actions: [
          IconButton(
            onPressed: widget.settingsController.toggleTheme,
            icon: Icon(switch (widget.settingsController.themeMode) {
              ThemeMode.dark => Icons.dark_mode_outlined,
              ThemeMode.light => Icons.light_mode_outlined,
              ThemeMode.system => Icons.brightness_auto_outlined,
            }),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                barrierColor: Colors.black12,
                builder: (context) {
                  final fontController = FontSizeController();

                  return SettingsSheet(
                    fontController: fontController,
                    settingsController: widget.settingsController,
                  );
                },
              );
            },
          ),
        ],
      ),

      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // --- 3. The List (Bottom Layer) ---
            if (widget.settingsController.isHorizontalScrolling)
              Positioned.fill(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: Quran.totalPagesCount,
                  onPageChanged: (page) => _updateReadingPosition(page + 1),
                  itemBuilder: (context, index) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.only(
                        top: totalTopHeaderHeight + 10,
                        bottom: 20,
                      ),
                      child: QuranPageWidget(
                        pageNumber: index + 1,
                        highlightedVerseListenable: _highlightedVerseNotifier,
                        settingsController: widget.settingsController,
                        onVerseTap: _onVerseTapped,
                      ),
                    );
                  },
                ),
              )
            else
              Positioned.fill(
                child: ScrollablePositionedList.builder(
                  // scrollDirection: Axis.horizontal,
                  itemCount: Quran.totalPagesCount,
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  initialScrollIndex:
                      (widget.initialPosition?.pageNumber ?? 1) - 1,
                  // This pushes the first page down so it's visible initially
                  padding: EdgeInsets.only(top: totalTopHeaderHeight + 10),
                  itemBuilder: (context, index) => RepaintBoundary(
                    child: QuranPageWidget(
                      pageNumber: index + 1,
                      key: ValueKey(index + 1),
                      highlightedVerseListenable: _highlightedVerseNotifier,
                      onVerseTap: _onVerseTapped,
                      settingsController: widget.settingsController,
                    ),
                  ),
                ),
              ),
            // --- 2. The Pinned Info Header (Middle Layer) ---
            // We position this EXACTLY below the AppBar
            PinnedHeader(
              statusBarHeight: statusBarHeight,
              appBarHeight: appBarHeight,
              infoHeight: infoHeaderHeight,
              decoration: appBarDecoration,
              currentPositionNotifier: _currentPositionNotifier,
              goToPage: _jumpToPage,
            ),
          ],
        ),
      ),
    );
  }
}

class QuranPageWidget extends StatefulWidget {
  const QuranPageWidget({
    required this.pageNumber,
    required this.settingsController,
    required this.highlightedVerseListenable,
    this.onVerseTap,
    super.key,
  });

  final int pageNumber;
  final ValueListenable<({int surah, int verse})?> highlightedVerseListenable;
  final void Function(int surah, int verse)? onVerseTap;
  final SettingsController settingsController;

  @override
  State<QuranPageWidget> createState() => _QuranPageWidgetState();
}

class _QuranPageWidgetState extends State<QuranPageWidget> {
  final FontSizeController _fontSizeController = FontSizeController();

  double _scaleFactor = 1;
  double _baseScale = 1;

  @override
  void initState() {
    super.initState();
    _fontSizeController.addListener(_rebuild);
  }

  @override
  void dispose() {
    _fontSizeController.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onVerseInteraction(
    int surah,
    int verseNumber, {
    required bool isLongPress,
  }) {
    // 1. Highlight the verse (Parent Logic)
    widget.onVerseTap?.call(surah, verseNumber);

    // 2. Handle specific action
    if (isLongPress && context.mounted) {
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: VerseMenuDialog(
            surah: surah,
            verse: (
              number: verseNumber,
              text: Quran.instance.getVerse(surah, verseNumber),
            ),
          ),
        ),
      );
    }
  }

  double _pageHorizontalPadding(double fontSize) {
    if (fontSize >= 40) return 6;
    if (fontSize >= 34) return 8;
    if (fontSize >= 28) return 10;
    return 14;
  }

  @override
  Widget build(BuildContext context) {
    final pageModel = QuranPageTextCache.instance.get(widget.pageNumber);

    final baseFontSize = _fontSizeController.verseFontSize * _scaleFactor;
    final symbolFontSize =
        _fontSizeController.verseSymbolFontSize * _scaleFactor;

    return GestureDetector(
      onScaleStart: (_) {
        _baseScale = _scaleFactor;
      },
      onScaleUpdate: (d) =>
          setState(() => _scaleFactor = (_baseScale * d.scale).clamp(0.8, 2.5)),
      onScaleEnd: (_) {
        final newSize = _fontSizeController.fontSize * _scaleFactor;
        _fontSizeController.setFontSize(newSize);
        setState(() => _scaleFactor = 1.0);
      },
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: _pageHorizontalPadding(baseFontSize),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...List.generate(pageModel.surahs.length, (i) {
              final surah = pageModel.surahs[i];
              final block = pageModel.blocks[i];

              return Column(
                children: [
                  if (surah.verses.any((v) => v.number == 1)) ...[
                    _buildHeader(surah),
                    if (surah.hasBasmala ||
                        widget.settingsController.fontFamily.isWarsh)
                      _buildBasmala(),
                  ],
                  _SurahTextBlock(
                    surahNumber: surah.surahNumber,
                    block: block,
                    fontSize: baseFontSize,
                    symbolFontSize: symbolFontSize,
                    highlightedVerseListenable:
                        widget.highlightedVerseListenable,
                    onInteraction: _onVerseInteraction,
                    settingsController: widget.settingsController,
                  ),
                ],
              );
            }),
            if (!widget.settingsController.isHorizontalScrolling)
              const Divider(height: 32, thickness: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SurahInPage surah) {
    final surahHeaderFontSize =
        (_fontSizeController.surahHeaderFontSize * _scaleFactor).clamp(0, 30);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(2),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
          fontFamily: widget.settingsController.fontFamily.name,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text('ترتيبها'),
                Text(
                  '(${getArabicNumber(surah.surahNumber)})',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FontFamily.arabicNumbersFontFamily.name,
                  ),
                ),
              ],
            ),
            Text(
              'سورة ${Quran.instance.getSurahNameArabic(surah.surahNumber)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: surahHeaderFontSize.toDouble(),
                height: 1.2,
                letterSpacing: 0,
                fontFamily: FontFamily.rustam.name,
              ),
            ),
            Column(
              children: [
                const Text('آياتها'),
                Text(
                  '(${getArabicNumber(Quran.instance.getVerseCount(surah.surahNumber))})',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: FontFamily.arabicNumbersFontFamily.name,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasmala() {
    final fontSize = (_fontSizeController.surahHeaderFontSize * _scaleFactor)
        .clamp(0, 50);
    final text = switch (widget.settingsController.fontFamily) {
      FontFamily.hafs => Quran.uthmanicHafsBasmala,
      FontFamily.rustam => Quran.madinaHafsBasmala,
      FontFamily.warsh => Quran.warshBasmala,
      FontFamily.scheherazade => Quran.madinaHafsBasmala,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize.toDouble(),
          fontFamily: widget.settingsController.fontFamily.name,
          letterSpacing: 0,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}

class _SurahTextBlock extends StatefulWidget {
  const _SurahTextBlock({
    required this.surahNumber,
    required this.block,
    required this.fontSize,
    required this.symbolFontSize,
    required this.highlightedVerseListenable,
    required this.onInteraction,
    required this.settingsController,
  });

  final int surahNumber;
  final SurahBlockText block;
  final double fontSize;
  final double symbolFontSize;
  final ValueListenable<({int surah, int verse})?> highlightedVerseListenable;
  final void Function(int s, int v, {required bool isLongPress}) onInteraction;
  final SettingsController settingsController;

  @override
  State<_SurahTextBlock> createState() => _SurahTextBlockState();
}

class _SurahTextBlockState extends State<_SurahTextBlock> {
  final GlobalKey _textKey = GlobalKey();

  ({int surah, int verse})? _highlight;

  @override
  void initState() {
    super.initState();
    _highlight = widget.highlightedVerseListenable.value;
    widget.highlightedVerseListenable.addListener(_onHighlightChanged);
  }

  @override
  void didUpdateWidget(covariant _SurahTextBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightedVerseListenable !=
        widget.highlightedVerseListenable) {
      oldWidget.highlightedVerseListenable.removeListener(_onHighlightChanged);
      _highlight = widget.highlightedVerseListenable.value;
      widget.highlightedVerseListenable.addListener(_onHighlightChanged);
    }
  }

  @override
  void dispose() {
    widget.highlightedVerseListenable.removeListener(_onHighlightChanged);
    super.dispose();
  }

  void _onHighlightChanged() {
    final oldH = _highlight;
    final newH = widget.highlightedVerseListenable.value;
    _highlight = newH;

    final affected =
        (oldH?.surah == widget.surahNumber) ||
        (newH?.surah == widget.surahNumber);

    if (affected && mounted) setState(() {});
  }

  void _handleTap(Offset localPos, bool isLongPress) {
    final renderObj = _textKey.currentContext?.findRenderObject();
    if (renderObj is! RenderParagraph) return;

    final index = renderObj.getPositionForOffset(localPos).offset;

    final verse = _findVerseAt(index);
    if (verse != null) {
      widget.onInteraction(widget.surahNumber, verse, isLongPress: isLongPress);
    }
  }

  int? _findVerseAt(int index) {
    final segs = widget.block.segments;
    int lo = 0;
    int hi = segs.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final s = segs[mid];
      if (index < s.start) {
        hi = mid - 1;
      } else if (index >= s.end) {
        lo = mid + 1;
      } else {
        return s.verse;
      }
    }
    return null;
  }

  TextAlign _calculateAlignment() {
    if (Quran.instance.getVerseCount(widget.surahNumber) <= 20) {
      return TextAlign.center;
    }
    return widget.fontSize > 34 ? TextAlign.center : TextAlign.justify;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final highlightBg = context.isDarkMode
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surfaceContainerHighest;

    final highlightStyle = TextStyle(backgroundColor: highlightBg);

    final symbolStyle = TextStyle(
      fontFamily: FontFamily.arabicNumbersFontFamily.name,
      fontSize: widget.symbolFontSize,
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.primary,
    );

    final selectedVerse = (_highlight?.surah == widget.surahNumber)
        ? _highlight?.verse
        : null;

    final children = <InlineSpan>[];
    for (final seg in widget.block.segments) {
      final bool isSelected = (selectedVerse == seg.verse);
      final String fullText = seg.text;

      // Variable to hold the symbol we will display
      String displaySymbol;
      String displayText;

      // WARSH LOGIC
      if (widget.settingsController.fontFamily == FontFamily.warsh &&
          fullText.isNotEmpty) {
        // 1. Extract the last character (The PUA Symbol)
        // We assume the last char is always the symbol in Warsh data
        final lastChar = fullText.substring(fullText.length - 1);
        final textPart = fullText.substring(0, fullText.length - 1).trim();

        // 2. Use the extracted symbol
        displayText = textPart;
        displaySymbol = lastChar;
      } else {
        // HAFS LOGIC
        // Use the text as is, and use the generated symbolText
        displayText = fullText;
        displaySymbol = seg.symbolText;
      }

      // 1. Verse Text Span
      children.add(
        TextSpan(text: displayText, style: isSelected ? highlightStyle : null),
      );

      // 2. Spacer
      children.add(const TextSpan(text: ' '));

      // 3. Symbol Span (Styled)
      children.add(
        TextSpan(
          text: displaySymbol,
          style: symbolStyle.copyWith(
            // If Warsh, we must use the Warsh font for the symbol too
            // otherwise the PUA code might not render or render wrong.
            fontFamily: widget.settingsController.fontFamily == FontFamily.warsh
                ? FontFamily.warsh.name
                : FontFamily.arabicNumbersFontFamily.name,
          ),
        ),
      );
      children.add(const TextSpan(text: ' '));
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (d) => _handleTap(d.localPosition, false),
      onLongPressStart: (d) => _handleTap(d.localPosition, true),
      child: RichText(
        key: _textKey,
        textAlign: _calculateAlignment(),
        textDirection: TextDirection.rtl,
        text: TextSpan(
          style: TextStyle(
            fontSize: widget.fontSize,
            fontFamily: widget.settingsController.fontFamily.name,
            fontWeight: widget.settingsController.fontWeight,
            color:
                theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface,
          ),
          children: children,
        ),
      ),
    );
  }
}
