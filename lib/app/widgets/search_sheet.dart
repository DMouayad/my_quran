import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/search/processor.dart';
import 'package:my_quran/app/services/search_service.dart';
import 'package:my_quran/app/utils.dart';
import 'package:my_quran/quran/quran.dart';

class QuranSearchBottomSheet extends StatefulWidget {
  const QuranSearchBottomSheet({
    required this.verseFontFamily,
    required this.onNavigateToPage,
    super.key,
  });

  final void Function(int page, {int? surah, int? verse}) onNavigateToPage;
  final FontFamily verseFontFamily;

  @override
  State<QuranSearchBottomSheet> createState() => _QuranSearchBottomSheetState();
}

class _QuranSearchBottomSheetState extends State<QuranSearchBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  bool _isSearching = false;

  SearchMatchMode _matchMode = SearchMatchMode.auto;
  SearchOperator _operator = SearchOperator.and;

  SearchResponse _response = const SearchResponse(
    hits: [],
    effectiveMode: SearchMatchMode.auto,
    normalizedQueryTokens: {},
    operatorUsed: SearchOperator.and,
    isTruncated: false,
    totalHits: 0,
  );

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _performSearch(query);
    });
  }

  int _searchSeq = 0;

  Future<void> _performSearch(String query) async {
    final mySeq = ++_searchSeq;

    if (query.trim().isEmpty) {
      setState(() {
        _response = const SearchResponse(
          hits: [],
          effectiveMode: SearchMatchMode.auto,
          normalizedQueryTokens: {},
          operatorUsed: SearchOperator.and,
          isTruncated: false,
          totalHits: 0,
        );
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final resp = await SearchService.search(
      query,
      mode: _matchMode,
      operator: _operator,
    );

    if (!mounted || mySeq != _searchSeq) return; // stale result

    setState(() {
      _response = resp;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final compact = isCompactWidth(context);
    final size = MediaQuery.of(context).size;

    return SizedBox(
      height: (compact || _controller.text.isNotEmpty)
          ? size.height * (compact ? 0.85 : 0.6)
          : null,
      child: Column(
        mainAxisSize: .min,
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(letterSpacing: 0),
              decoration: InputDecoration(
                hintText: 'ابحث عن آية...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.applyOpacity(0.3),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          _buildFiltersBar(context),
          _buildResultList(colorScheme, !compact),
        ],
      ),
    );
  }

  Widget _buildFiltersBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final tokensCount = ArabicTextProcessor.tokenize(
      _controller.text,
    ).map(ArabicTextProcessor.normalize).where((t) => t.isNotEmpty).length;

    final showOperator = tokensCount >= 2;

    final shown = _response.hits.length;
    final total = _response.totalHits;

    // When Auto is active, highlight the effective mode in
    // the segmented control.
    SearchMatchMode selectedModeForUi() {
      if (!_matchMode.isAuto) return _matchMode;
      return _response.effectiveMode == SearchMatchMode.auto
          ? SearchMatchMode.prefix
          : _response.effectiveMode;
    }

    String operatorLabel(SearchOperator op) => switch (op) {
      SearchOperator.and => 'جميع الكلمات',
      SearchOperator.or => 'أي كلمة',
    };

    Widget countWidget() {
      if (total == 0) return const SizedBox.shrink();
      return Text(
        _response.isTruncated ? 'عرض $shown من $total' : 'عدد النتائج: $total',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    void selectUserMode(SearchMatchMode m) {
      setState(() => _matchMode = m);
      _performSearch(_controller.text);
    }

    Widget modeSegmented() {
      return SegmentedButton<SearchMatchMode>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.comfortable),
        segments: const [
          ButtonSegment(value: SearchMatchMode.exact, label: Text('مطابق')),
          ButtonSegment(value: SearchMatchMode.prefix, label: Text('بداية')),
          ButtonSegment(value: SearchMatchMode.contains, label: Text('داخل')),
          ButtonSegment(value: SearchMatchMode.flexible, label: Text('مرن')),
        ],
        selected: {selectedModeForUi()},
        onSelectionChanged: (v) => selectUserMode(v.first),
      );
    }

    Widget operatorControl() {
      return PopupMenuButton<SearchOperator>(
        initialValue: _operator,
        onSelected: (op) {
          setState(() => _operator = op);
          _performSearch(_controller.text);
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: SearchOperator.and,
            child: Text('مطابقة: جميع الكلمات'),
          ),
          PopupMenuItem(
            value: SearchOperator.or,
            child: Text('مطابقة: أي كلمة'),
          ),
        ],
        child: Chip(
          avatar: const Icon(Icons.filter_alt_outlined, size: 18),
          label: Text('مطابقة: ${operatorLabel(_operator)}'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          modeSegmented(),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [if (showOperator) operatorControl(), countWidget()],
          ),
        ],
      ),
    );
  }

  Widget _buildResultList(ColorScheme colorScheme, bool isDesktop) {
    final hits = _response.hits;

    if (isDesktop && _controller.text.isEmpty) {
      return const SizedBox.shrink();
    }

    if (hits.isEmpty && _controller.text.isNotEmpty && !_isSearching) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد نتائج',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }
    return Expanded(
      child: Stack(
        children: [
          ListView.separated(
            itemCount: hits.length,
            separatorBuilder: (c, i) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final hit = hits[index];
              return SearchResultItem(
                verseFontFamily: widget.verseFontFamily,
                hit: hit,
                effectiveMode: _response.effectiveMode,
                onTap: () {
                  Navigator.pop(context);

                  final page = Quran.instance.getPageNumber(
                    hit.surah,
                    hit.verse,
                  );

                  widget.onNavigateToPage(
                    page,
                    surah: hit.surah,
                    verse: hit.verse,
                  );
                },
              );
            },
          ),
          if (_isSearching)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: colorScheme.primary,
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }
}

class SearchResultItem extends StatelessWidget {
  const SearchResultItem({
    required this.verseFontFamily,
    required this.hit,
    required this.effectiveMode,
    required this.onTap,
    super.key,
  });

  final SearchHit hit;
  final SearchMatchMode effectiveMode;
  final VoidCallback onTap;
  final FontFamily verseFontFamily;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final plain = Quran.instance.getVerseInPlainText(hit.surah, hit.verse);
    final display = Quran.instance.getVerse(hit.surah, hit.verse);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header: Surah Name & Verse Number ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${Quran.instance.getSurahNameArabic(hit.surah)} - '
                    '${getArabicNumber(hit.verse)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: FontFamily.arabicNumbersFontFamily.name,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: colorScheme.outline,
                ),
              ],
            ),
            const SizedBox(height: 8),

            _HighlightedText(
              debug: kDebugMode,
              plainText: plain,
              displayText: display,
              matchedPlainWordIndexes: hit.matchedWordIndexes.toSet(),
              highlightColor: colorScheme.primary,
              baseColor: colorScheme.onSurface,
              verseFontFamily: verseFontFamily,
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.verseFontFamily,
    required this.plainText,
    required this.displayText,
    required this.matchedPlainWordIndexes,
    required this.highlightColor,
    required this.baseColor,
    this.debug = false,
  });

  final String plainText;
  final String displayText;
  final Set<int> matchedPlainWordIndexes;
  final Color highlightColor;
  final Color baseColor;
  final FontFamily verseFontFamily;
  final bool debug;

  void _d(String msg) {
    if (kDebugMode && debug) debugPrint(msg);
  }

  // Tokenization helpers
  List<String> _splitDisplayTokens(String s) =>
      s.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

  String _stripBidi(String s) =>
      s.replaceAll(RegExp(r'[\u200E\u200F\u202A-\u202E\u2066-\u2069]'), '');

  bool _containsPua(String s) => s.runes.any((r) => r >= 0xE000 && r <= 0xF8FF);

  bool _hasArabicLetter(String s) =>
      RegExp(r'[\u0621-\u064A\u0671]').hasMatch(s);

  bool _isDisplayWordToken(String token) {
    final t = _stripBidi(token).trim();
    if (t.isEmpty) return false;
    if (_containsPua(t)) return true;

    // Support normal-unicode display too:
    final norm = ArabicTextProcessor.normalize(t);
    return norm.isNotEmpty && _hasArabicLetter(norm);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // ---- 1) Plain "content words" count must match SearchService's
    // indexing logic.
    final plainTokens = ArabicTextProcessor.tokenize(plainText);

    final plainContentWords = <String>[];
    for (final t in plainTokens) {
      final n = ArabicTextProcessor.normalize(t);
      if (n.isEmpty) continue;
      if (!_hasArabicLetter(n)) continue;
      plainContentWords.add(t);
    }

    // ---- 2) Keep original display tokens for rendering (PUA+RLM ordering),
    // but remove tokens that become empty after stripping bidi.
    final displayTokens = _splitDisplayTokens(
      displayText,
    ).where((t) => _stripBidi(t).trim().isNotEmpty).toList();

    // ---- 3) Build display->plain mapping (consume only display word tokens)
    final displayToPlain = <int?>[];
    int p = 0;

    for (final dt in displayTokens) {
      if (_isDisplayWordToken(dt)) {
        displayToPlain.add(p < plainContentWords.length ? p : null);
        p++;
      } else {
        displayToPlain.add(null);
      }
    }

    // ---- 4) Find first match for slicing
    int firstMatchPlainIndex = -1;
    if (matchedPlainWordIndexes.isNotEmpty) {
      firstMatchPlainIndex = matchedPlainWordIndexes.reduce(
        (a, b) => a < b ? a : b,
      );
    }

    int firstMatchDisplayIndex = -1;
    if (firstMatchPlainIndex != -1) {
      firstMatchDisplayIndex = displayToPlain.indexWhere(
        (m) => m == firstMatchPlainIndex,
      );
    }

    int startDisplayIndex = 0;
    bool showStartEllipsis = false;
    if (firstMatchDisplayIndex > 10) {
      startDisplayIndex = firstMatchDisplayIndex - 3;
      showStartEllipsis = true;
    }

    final slicedDisplayTokens = displayTokens.sublist(startDisplayIndex);
    final slicedMap = displayToPlain.sublist(startDisplayIndex);

    // Optional trimming similar to your old behavior:
    if (verseFontFamily == FontFamily.hafs) {
      while (slicedDisplayTokens.isNotEmpty &&
          !_isDisplayWordToken(slicedDisplayTokens.last)) {
        slicedDisplayTokens.removeLast();
        slicedMap.removeLast();
      }
    }

    final isWarsh = verseFontFamily == FontFamily.warsh;

    _d(
      'plainContentWords=${plainContentWords.length}'
      ' displayTokens=${displayTokens.length}',
    );

    return RichText(
      textDirection: TextDirection.rtl,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontSize: isWarsh ? 26 : 20,
          color: baseColor,
          height: 1.8,
          fontWeight: isWarsh ? FontWeight.w500 : null,
          fontFamily: verseFontFamily.name,
          letterSpacing: 0,
        ),
        children: [
          if (showStartEllipsis)
            TextSpan(
              text: '... ',
              style: TextStyle(color: baseColor.applyOpacity(0.8)),
            ),
          ...List.generate(slicedDisplayTokens.length, (i) {
            final displayTok = slicedDisplayTokens[i];
            final plainIndex = slicedMap[i];

            final isMatch =
                plainIndex != null &&
                matchedPlainWordIndexes.contains(plainIndex);

            return TextSpan(
              text: '$displayTok ',
              style: isMatch
                  ? TextStyle(
                      backgroundColor: highlightColor,
                      color: colorScheme.onPrimary,
                    )
                  : null,
            );
          }),
        ],
      ),
    );
  }
}
