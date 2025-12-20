import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:my_quran/app/utils.dart';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:my_quran/app/font_size_controller.dart';
import 'package:my_quran/app/services/reading_position_service.dart';
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/widgets/font_settings_sheet.dart';
import 'package:my_quran/app/widgets/navigation_sheet.dart';
import 'package:my_quran/app/widgets/bookmarks_sheet.dart';
import 'package:my_quran/app/widgets/verse_menu_overlay.dart';
import 'package:my_quran/app/widgets/search_sheet.dart';
import 'package:my_quran/quran/quran.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.onThemeToggle,
    required this.onFontFamilyChange,
    required this.fontFamily,
    required this.themeMode,
    this.initialPosition,
    super.key,
  });

  final VoidCallback onThemeToggle;
  final ValueChanged<FontFamily> onFontFamilyChange;
  final ReadingPosition? initialPosition;
  final ThemeMode themeMode;
  final FontFamily fontFamily;

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  // This allows Search/Bookmarks to control what is highlighted
  ({int surah, int verse})? _highlightedVerse;
  late final ValueNotifier<ReadingPosition> _currentPositionNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
  }

  @override
  void dispose() {
    ReadingPositionService.savePosition(_currentPositionNotifier.value);
    _itemPositionsListener.itemPositions.removeListener(_onScrollUpdate);
    WidgetsBinding.instance.removeObserver(this);
    _currentPositionNotifier.dispose();
    super.dispose();
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

    // Sort positions by index to ensure order
    final sortedPositions = positions.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    final firstItem = sortedPositions.first;

    // --- Header Page Detection ---
    // We want the page that occupies the "reading line".
    ItemPosition bestCandidate = firstItem;
    for (final pos in sortedPositions) {
      // If this item covers the top 15% of the screen
      if (pos.itemTrailingEdge > 0.15) {
        bestCandidate = pos;
        break;
      }
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
      final surahNum = firstSurah['surah'] as int;
      final verseNum = firstSurah['start'] as int;
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
      setState(
        () =>
            _highlightedVerse = (surah: highlightSurah, verse: highlightVerse),
      );
    } else {
      setState(() => _highlightedVerse = null);
    }

    _updateReadingPosition(pageNumber);

    final index = (pageNumber - 1).clamp(0, Quran.totalPagesCount - 1);

    // 2. Calculate Alignment (Smart Scroll)
    double alignment = 0;

    if (highlightSurah != null && highlightVerse != null) {
      // Get data for this page to find where our verse is located relative to others
      final pageData = Quran.instance.getPageData(pageNumber);

      int totalVersesOnPage = 0;
      int targetVerseIndex = 0;
      bool found = false;

      // Count verses and find our index
      for (final surahData in pageData) {
        final sNum = surahData['surah'] as int;
        final start = surahData['start'] as int;
        final end = surahData['end'] as int;

        for (int v = start; v <= end; v++) {
          if (sNum == highlightSurah && v == highlightVerse) {
            targetVerseIndex = totalVersesOnPage;
            found = true;
          }
          totalVersesOnPage++;
        }
      }

      if (found && totalVersesOnPage > 0) {
        // Calculate ratio (0.0 = Top, 1.0 = Bottom)
        final ratio = targetVerseIndex / totalVersesOnPage;

        // Logic:
        // If ratio is 0 (top), alignment is 0.
        // If ratio is 1 (bottom), we want to pull the page UP.
        // A heuristic value of -0.5 usually centers the bottom half well.
        // We clamp it so we don't scroll into void.
        if (ratio > 0.5) {
          // Move top of page up by a percentage of the viewport
          alignment = -0.2; // Adjust this value (-0.2 to -0.5) to taste
        }
      }
    }

    // 3. Jump with Alignment
    _itemScrollController.jumpTo(index: index, alignment: alignment);
  }

  // Helper to handle manual tap selection
  void _onVerseTapped(int surah, int verse) {
    setState(() {
      if (_highlightedVerse?.surah == surah &&
          _highlightedVerse?.verse == verse) {
        // Deselect if tapped again
        _highlightedVerse = null;
      } else {
        _highlightedVerse = (surah: surah, verse: verse);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Heights
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double appBarHeight = kToolbarHeight; // Standard 56.0
    const double infoHeaderHeight = 44; // Height of our Surah/Page strip

    // Total height obscuring the top
    final double totalTopHeaderHeight =
        statusBarHeight + appBarHeight + infoHeaderHeight;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // 2. Define Glass Style (Reusable)
    final glassDecoration = BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.85),
      border: Border(
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
    );
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true, // Critical for glass effect
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.surfaceContainer,
        foregroundColor: colorScheme.secondary,
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
              onPressed: () => showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (_) => BookmarksSheet(
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
            ),
            Expanded(
              child: Text(
                'قرآني',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: context.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(decoration: glassDecoration),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => MinimalFontSizeControl.show(context),
            icon: const Icon(Icons.format_size_outlined),
          ),
          IconButton(
            onPressed: widget.onThemeToggle,
            icon: Icon(switch (widget.themeMode) {
              ThemeMode.dark => Icons.dark_mode_outlined,
              ThemeMode.light => Icons.light_mode_outlined,
              ThemeMode.system => Icons.brightness_auto_outlined,
            }),
          ),
        ],
      ),

      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // --- 3. The List (Bottom Layer) ---
            Positioned.fill(
              child: ScrollablePositionedList.builder(
                itemCount: Quran.totalPagesCount,
                itemScrollController: _itemScrollController,
                itemPositionsListener: _itemPositionsListener,
                initialScrollIndex:
                    (widget.initialPosition?.pageNumber ?? 1) - 1,
                // This pushes the first page down so it's visible initially
                padding: EdgeInsets.only(top: totalTopHeaderHeight + 10),
                itemBuilder: (context, index) => QuranPageWidget(
                  pageNumber: index + 1,
                  key: ValueKey(index + 1),
                  highlightedVerse: _highlightedVerse,
                  onVerseTap: _onVerseTapped,
                ),
              ),
            ),

            // --- 2. The Pinned Info Header (Middle Layer) ---
            // We position this EXACTLY below the AppBar
            Positioned(
              top: statusBarHeight + appBarHeight, // Push down by AppBar height
              left: 0,
              right: 0,
              height: infoHeaderHeight,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontFamily: FontFamily.arabicNumbersFontFamily.name,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    child: Container(
                      decoration: glassDecoration,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ValueListenableBuilder<ReadingPosition>(
                        valueListenable: _currentPositionNotifier,
                        builder: (context, position, _) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${getArabicNumber(position.surahNumber)} - '
                                    '${Quran.instance.getSurahNameArabic(position.surahNumber)}',
                                  ),

                                  Text(
                                    'جزء ${getArabicNumber(position.juzNumber)}',
                                  ),
                                ],
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    getArabicNumber(position.pageNumber),
                                    key: ValueKey(position.pageNumber),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
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
    this.highlightedVerse,
    this.onVerseTap,
    super.key,
  });

  final int pageNumber;
  final ({int surah, int verse})? highlightedVerse;
  final void Function(int surah, int verse)? onVerseTap;

  @override
  State<QuranPageWidget> createState() => _QuranPageWidgetState();
}

class _QuranPageWidgetState extends State<QuranPageWidget> {
  late final QuranPage pageDataModel;
  final FontSizeController _fontSizeController = FontSizeController();
  final GlobalKey _richTextKey = GlobalKey(); // Key to access the text renderer

  // Store the text range of each verse to map taps later
  // Key: Verse Identifier, Value: Range(Start Index, End Index)
  final Map<({int surah, int verse}), ({int start, int end})> _verseRanges = {};

  double _scaleFactor = 1;
  double _baseScale = 1;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _loadPageData();
    _fontSizeController.addListener(_rebuild);
  }

  @override
  void dispose() {
    _fontSizeController.removeListener(_rebuild);
    _removeOverlay();
    super.dispose();
  }

  @override
  void deactivate() {
    _removeOverlay();
    super.deactivate();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _loadPageData() {
    final rawData = Quran.instance.getPageData(widget.pageNumber);
    final List<SurahInPage> surahs = [];
    for (final item in rawData) {
      final surahNum = item['surah'] as int;
      final start = item['start'] as int;
      final end = item['end'] as int;
      final verses = <Verse>[];
      for (var i = start; i <= end; i++) {
        verses.add((number: i, text: Quran.instance.getVerse(surahNum, i)));
      }
      surahs.add(SurahInPage(surahNumber: surahNum, verses: verses));
    }
    pageDataModel = QuranPage(pageNumber: widget.pageNumber, surahs: surahs);
  }

  // --- HIT TEST LOGIC ---

  void _handleGlobalTap(Offset localPosition, {bool isLongPress = false}) {
    final renderObject = _richTextKey.currentContext?.findRenderObject();
    if (renderObject is! RenderParagraph) return;

    // 1. Get the text index (character position) from the tap coordinates
    final textPosition = renderObject.getPositionForOffset(localPosition);
    final index = textPosition.offset;

    // 2. Find which verse contains this index
    for (final entry in _verseRanges.entries) {
      final range = entry.value;
      if (index >= range.start && index < range.end) {
        final verseId = entry.key;
        // Found it!
        _onVerseInteraction(
          verseId.surah,
          verseId.verse,
          isLongPress: isLongPress,
        );
        return;
      }
    }

    if (!isLongPress) {
      _removeOverlay();
    }
  }

  void _onVerseInteraction(
    int surah,
    int verseNumber, {
    required bool isLongPress,
  }) {
    // 1. Highlight the verse (Parent Logic)
    widget.onVerseTap?.call(surah, verseNumber);
    HapticFeedback.selectionClick();

    // 2. Handle specific action
    if (isLongPress) {
      _showOverlay(surah, verseNumber);
    } else {
      _removeOverlay(); // Close any existing menu on new tap
    }
  }

  void _showOverlay(int surah, int verseNumber) {
    _removeOverlay();
    // Create a dummy verse object for the overlay
    final verseObj = (
      number: verseNumber,
      text: Quran.instance.getVerse(surah, verseNumber),
    );

    _overlayEntry = OverlayEntry(
      builder: (ctx) => VerseMenuOverlay(
        surah: surah,
        verse: verseObj,
        onDismiss: () {
          _removeOverlay();
          if (mounted) setState(() {}); // Refresh
        },
        onBookmarkToggled: () => setState(() {}),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // --- BUILDER ---

  @override
  Widget build(BuildContext context) {
    final baseFontSize = _fontSizeController.verseFontSize * _scaleFactor;
    final symbolFontSize =
        _fontSizeController.verseSymbolFontSize * _scaleFactor;

    return GestureDetector(
      // 1. Global Gesture Detector wraps the whole page
      onScaleStart: (_) {
        _baseScale = _scaleFactor;
        _removeOverlay();
      },
      onScaleUpdate: (d) =>
          setState(() => _scaleFactor = (_baseScale * d.scale).clamp(0.8, 2.5)),
      onScaleEnd: (_) {
        final newSize = _fontSizeController.fontSize * _scaleFactor;
        _fontSizeController.setFontSize(newSize);
        setState(() => _scaleFactor = 1.0);
      },
      // 2. Hit Testing Callbacks
      onTapUp: (details) => _handleGlobalTap(details.localPosition),
      onLongPressStart: (details) =>
          _handleGlobalTap(details.localPosition, isLongPress: true),

      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...pageDataModel.surahs.map((surah) {
              return Column(
                children: [
                  if (surah.verses.any((v) => v.number == 1)) ...[
                    _buildHeader(surah),
                    if (surah.hasBasmala) _buildBasmala(),
                  ],
                  // 3. THE RICH TEXT
                  _buildRichText(surah, baseFontSize, symbolFontSize),
                ],
              );
            }),
            const Divider(height: 32, thickness: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildRichText(SurahInPage surah, double fontSize, double symbolSize) {
    // We must track the current character index manually to build our Hit Map
    // Note: This counter resets for each RichText widget (each Surah block)
    // BUT our Hit Test logic looks at the *RenderParagraph*.
    // So we need to rebuild the map specifically for this RenderParagraph.
    // However, since we have multiple RichTexts (one per Surah),
    // we need a separate GlobalKey for each Surah?

    // To make hit testing work with multiple Surahs on one page,
    // we should give each Surah's RichText its own GlobalKey.
    // Let's create a small wrapper widget or use a KeyedSubtree logic.
    // Or simpler: Just use a localized Builder.

    return Builder(
      builder: (context) {
        return _SurahTextBlock(
          surah: surah,
          fontSize: fontSize,
          symbolSize: symbolSize,
          highlightedVerse: widget.highlightedVerse,
          onInteraction: _onVerseInteraction,
        );
      },
    );
  }

  Widget _buildHeader(SurahInPage surah) {
    final surahHeaderFontSize =
        _fontSizeController.surahHeaderFontSize * _scaleFactor;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            'ترتيبها\n (${getArabicNumber(surah.surahNumber)})',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontFamily.arabicNumbersFontFamily.name,
            ),
          ),
          Text(
            'سورة ${Quran.instance.getSurahNameArabic(surah.surahNumber)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: surahHeaderFontSize,
              height: 1.5,
              letterSpacing: 0,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          Text(
            'آياتها\n (${getArabicNumber(Quran.instance.getVerseCount(surah.surahNumber))})',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: FontFamily.arabicNumbersFontFamily.name,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasmala() {
    final fontSize = _fontSizeController.surahHeaderFontSize * _scaleFactor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        Quran.basmala,
        style: TextStyle(
          fontSize: fontSize,
          letterSpacing: 0,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// This isolates the GlobalKey and HitTest logic per Surah block
class _SurahTextBlock extends StatefulWidget {
  const _SurahTextBlock({
    required this.surah,
    required this.fontSize,
    required this.symbolSize,
    required this.highlightedVerse,
    required this.onInteraction,
  });
  final SurahInPage surah;
  final double fontSize;
  final double symbolSize;
  final ({int surah, int verse})? highlightedVerse;
  final void Function(int s, int v, {required bool isLongPress}) onInteraction;

  @override
  State<_SurahTextBlock> createState() => _SurahTextBlockState();
}

class _SurahTextBlockState extends State<_SurahTextBlock> {
  final GlobalKey _textKey = GlobalKey();
  // Maps character indices to verse numbers for THIS block
  final Map<int, ({int start, int end})> _ranges = {};

  void _handleTap(Offset localPos, bool isLongPress) {
    final renderObj = _textKey.currentContext?.findRenderObject();
    if (renderObj is! RenderParagraph) return;

    final textPos = renderObj.getPositionForOffset(localPos);
    final index = textPos.offset;

    // Find verse
    for (final entry in _ranges.entries) {
      final verseNum = entry.key;
      final range = entry.value;
      if (index >= range.start && index < range.end) {
        widget.onInteraction(
          widget.surah.surahNumber,
          verseNum,
          isLongPress: isLongPress,
        );
        return;
      }
    }
  }

  TextAlign _calculateAlignment(double fontSize, double screenWidth) {
    if (fontSize > 34) {
      return TextAlign.center;
    }

    // Normal Text: Keep the nice boxy look
    return TextAlign.justify;
  }

  @override
  Widget build(BuildContext context) {
    _ranges.clear();
    final isDarkMode = Theme.brightnessOf(context) == Brightness.dark;
    int charCount = 0;
    final spans = <InlineSpan>[];
    final highlightedTextStyle = TextStyle(
      backgroundColor: isDarkMode
          ? Theme.of(context).colorScheme.surfaceContainerHigh
          : Theme.of(context).colorScheme.surfaceContainerHighest,
    );
    for (final verse in widget.surah.verses) {
      // 1. Text
      final String text = verse.text;

      // 2. Determine Selection
      final isSelected =
          widget.highlightedVerse?.surah == widget.surah.surahNumber &&
          widget.highlightedVerse?.verse == verse.number;

      // 3. Calculate Range
      final start = charCount;
      // Verse Text length
      charCount += text.length;
      // Space (1)
      charCount += 1;
      // Symbol length
      final symbol = ' ${Quran.instance.getVerseEndSymbol(verse.number)} ';
      charCount += symbol.length;
      // Trailing Spaces (2)
      charCount += 2;

      final end = charCount;
      _ranges[verse.number] = (start: start, end: end);

      // 4. Build Spans
      spans.add(
        TextSpan(text: text, style: isSelected ? highlightedTextStyle : null),
      );
      spans.add(
        TextSpan(
          text: symbol,
          style: TextStyle(
            fontFamily: FontFamily.arabicNumbersFontFamily.name,
            color: context.colorScheme.primary,
            fontSize: widget.symbolSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return GestureDetector(
      onTapUp: (d) => _handleTap(d.localPosition, false),
      onLongPressStart: (d) => _handleTap(d.localPosition, true),
      child: RichText(
        key: _textKey,
        textAlign: Quran.instance.getVerseCount(widget.surah.surahNumber) < 20
            ? TextAlign.center
            : _calculateAlignment(
                widget.fontSize,
                MediaQuery.of(context).size.width,
              ),
        textDirection: TextDirection.rtl,
        textWidthBasis: TextWidthBasis.longestLine,
        text: TextSpan(
          style: TextStyle(
            fontSize: widget.fontSize,
            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            wordSpacing: widget.fontSize >= 38 ? -1 : 0,
          ),
          children: spans,
        ),
      ),
    );
  }
}
