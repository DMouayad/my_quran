import 'dart:async';

import 'package:flutter/material.dart';

import 'package:my_quran/app/search/processor.dart';
import 'package:my_quran/quran/quran.dart';
import 'package:my_quran/app/search/models.dart';
import 'package:my_quran/app/services/search_service.dart';

class QuranSearchBottomSheet extends StatefulWidget {
  const QuranSearchBottomSheet({required this.onNavigateToPage, super.key});
  final void Function(int page, {int? surah, int? verse}) onNavigateToPage;

  @override
  State<QuranSearchBottomSheet> createState() => _QuranSearchBottomSheetState();
}

class _QuranSearchBottomSheetState extends State<QuranSearchBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  List<SearchResult> _results = [];
  bool _isSearching = false;
  bool _isExactMatch = false;
  // Debounce timer to prevent search on every keystroke
  Timer? _debounce;
  Set<String> _currentQueryTokens = {};

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
        _currentQueryTokens = {};
      });
      return;
    }

    setState(() => _isSearching = true);

    final rawTokens = ArabicTextProcessor.tokenize(query);
    _currentQueryTokens = rawTokens.map(ArabicTextProcessor.normalize).toSet();

    // Pass the toggle value to the service
    final results = SearchService.search(query, exactMatch: _isExactMatch);

    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
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
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // FILTER CHIP (Exact Match Toggle)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('إظهار النتائج المطابقة فقط'),
                  selected: _isExactMatch,
                  onSelected: (bool selected) {
                    setState(() {
                      _isExactMatch = selected;
                    });
                    // Re-run search immediately with new setting
                    _performSearch(_controller.text);
                  },
                  selectedColor: colorScheme.primaryContainer,
                  checkmarkColor: colorScheme.primary,
                ),

                if (_results.isNotEmpty) ...[
                  const Spacer(),
                  Text(
                    'عدد النتائج: ${_results.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // --- Results List ---
          Expanded(
            child:
                _results.isEmpty && _controller.text.isNotEmpty && !_isSearching
                ? Center(
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
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (c, i) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return SearchResultItem(
                        queryTokens: _currentQueryTokens,
                        result: result,
                        highlightExactMatchOnly: _isExactMatch,
                        query: _controller.text,
                        onTap: () {
                          // 1. Close Sheet
                          Navigator.pop(context);

                          // 2. Calculate Page Number
                          final page = Quran.instance.getPageNumber(
                            result.surah,
                            result.verse,
                          );

                          // 3. Navigate with Highlight Info
                          widget.onNavigateToPage(
                            page,
                            surah: result.surah,
                            verse: result.verse,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SearchResultItem extends StatelessWidget {
  const SearchResultItem({
    required this.result,
    required this.query,
    required this.onTap,
    required this.queryTokens,
    required this.highlightExactMatchOnly,
    super.key,
  });

  final SearchResult result;
  final Set<String> queryTokens;
  final bool highlightExactMatchOnly;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 1. Get the full verse text
    final String fullText = Quran.instance.getVerse(result.surah, result.verse);

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
                    '${Quran.instance.getSurahNameArabic(result.surah)} - '
                    '${result.verse}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'آية- ${result.verse} ',
                  style: TextStyle(fontSize: 14, color: colorScheme.primary),
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

            // --- Body: Highlighted Verse Text ---
            _HighlightedText(
              text: fullText,
              query: query,
              queryTokens: queryTokens,
              highlightExactMatchOnly: highlightExactMatchOnly,
              highlightColor: colorScheme.primary,
              baseColor: colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.highlightColor,
    required this.baseColor,
    required this.queryTokens,
    required this.highlightExactMatchOnly,
  });
  final String text;
  final String query;
  final Color highlightColor;
  final Color baseColor;
  final Set<String> queryTokens;
  final bool highlightExactMatchOnly;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Tokenize the verse text (keep punctuation for display)
    // We split by space to process word by word
    final List<String> verseWords = text.split(' ');

    return RichText(
      textDirection: TextDirection.rtl,
      maxLines: 2, // Compact view
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontSize: 18,
          color: baseColor,
          height: 1.8,
          fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
        ),
        children: verseWords.map((word) {
          // Normalize the word from the verse to check against query
          // We must strip diacritics/symbols to compare,
          // but we DISPLAY the original 'word'
          final cleanWord = ArabicTextProcessor.normalize(word);

          bool isMatch = false;

          if (highlightExactMatchOnly) {
            isMatch = queryTokens.contains(cleanWord);
          } else {
            for (final q in queryTokens) {
              if (cleanWord.startsWith(q)) {
                isMatch = true;
                break;
              }
            }
          }

          return TextSpan(
            text: '$word ', // Add space back
            style: isMatch
                ? TextStyle(
                    backgroundColor: colorScheme.primaryContainer,
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }
}
