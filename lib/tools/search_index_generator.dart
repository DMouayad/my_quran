// ignore_for_file: avoid_print ()

import 'dart:convert';
import 'dart:io';

import 'package:my_quran/app/search/processor.dart';

/// Generates search indexes for multiple narrations.
/// Run with: dart run search_index_generator.dart
void main() async {
  // 1. Generate HAFS Index (Combines Uthmani + Simple text for better matching)
  await _generateIndexForNarration(
    label: 'HAFS',
    inputFiles: ['assets/quran.json', 'lib/tools/quran_simple_clean.json'],
    outputFile: 'assets/search_index_hafs.json',
  );

  print('------------------------------------------------');

  // 2. Generate WARSH Index (Uses Warsh text)
  await _generateIndexForNarration(
    label: 'WARSH',
    inputFiles: ['assets/warsh.json'],
    outputFile: 'assets/search_index_warsh.json',
  );
}

Future<void> _generateIndexForNarration({
  required String label,
  required List<String> inputFiles,
  required String outputFile,
}) async {
  print('🔨 [$label] Building search index...');

  // Map<normalized_word, Set<verse_id>>
  final Map<String, Set<int>> invertedIndex = {};
  int filesProcessed = 0;

  for (final filePath in inputFiles) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('⚠️ Warning: $filePath not found. Skipping.');
      continue;
    }

    print('   📄 Processing $filePath...');
    final String content = await file.readAsString();
    final Map<String, dynamic> data =
        jsonDecode(content) as Map<String, dynamic>;

    // Iterate Surahs
    for (final surahEntry in data.entries) {
      final surahNumber = int.parse(surahEntry.key);
      final verses = surahEntry.value as Map<String, dynamic>;

      // Iterate Verses
      for (final verseEntry in verses.entries) {
        final verseNumber = int.parse(verseEntry.key);
        final text = verseEntry.value.toString();

        // Create unique verse ID
        final verseId = surahNumber * 1000 + verseNumber;

        // Process text
        _processVerseText(text, verseId, invertedIndex);
      }
    }
    filesProcessed++;
  }

  if (filesProcessed == 0) {
    print('❌ Error: No input files were processed for $label.');
    return;
  }

  // Sort keys for binary search optimization
  final sortedKeys = invertedIndex.keys.toList()..sort();

  // Convert sets to sorted lists for JSON
  final indexData = <String, List<int>>{};
  for (final key in sortedKeys) {
    indexData[key] = invertedIndex[key]!.toList()..sort();
  }

  // Create final output
  final output = {'keys': sortedKeys, 'data': indexData};

  // Write to file
  final out = File(outputFile);
  await out.writeAsString(jsonEncode(output));

  print('✅ [$label] Index generated!');
  print('📊 Keywords: ${sortedKeys.length}');
  print('📝 Output: ${out.path}');
}

/// Process verse text and add to inverted index
void _processVerseText(
  String text,
  int verseId,
  Map<String, Set<int>> invertedIndex,
) {
  // Use the tokenizer (handles punctuation removal)
  final tokens = ArabicTextProcessor.tokenize(text);

  for (final token in tokens) {
    final Set<String> variantsToNormalize = {};

    // Logic: Handle Dagger Alef variations (Keeping your existing logic)
    if (token.contains('\u0670')) {
      variantsToNormalize.add(token.replaceAll('\u0670', 'ا'));
      variantsToNormalize.add(token.replaceAll('\u0670', ''));
    } else {
      variantsToNormalize.add(token);
    }

    // Normalize and index all generated variants
    for (final variant in variantsToNormalize) {
      final normalized = _normalizeBase(variant);
      if (normalized.isNotEmpty) {
        // Validation: Ensure we only index actual Arabic words
        // This regex allows Arabic letters + Hamza. Excludes numbers/symbols.
        if (RegExp(r'[\u0621-\u064A]').hasMatch(normalized)) {
          invertedIndex.putIfAbsent(normalized, () => <int>{});
          invertedIndex[normalized]!.add(verseId);
        }
      }
    }
  }
}

String _normalizeBase(String text) {
  // 1. Remove PUA Symbols (Crucial for Warsh!)
  // Removes End of Ayah marks or custom font glyphs (E000-F8FF)
  String normalized = text.replaceAll(RegExp(r'[\uE000-\uF8FF]'), '');

  // 2. Remove punctuation and symbols
  normalized = normalized.replaceAll(
    RegExp(r'[\p{P}\p{S}\p{N}\-\(\)\[\]\{\}]+', unicode: true),
    '',
  );

  // 3. Remove all diacritics
  normalized = normalized.replaceAll(
    RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'),
    '',
  );

  // 4. Character Normalization
  normalized = normalized.replaceAll(RegExp('[أإآٱ]'), 'ا');
  normalized = normalized.replaceAll('ة', 'ه');
  normalized = normalized.replaceAll('ى', 'ي');

  // Hamza Normalization (Your Logic)
  normalized = normalized.replaceAll('ؤ', 'و');
  normalized = normalized.replaceAll('ئ', 'ء');
  normalized = normalized.replaceAll('ء', ''); // Strip Hamza on line?

  // Tatweel
  normalized = normalized.replaceAll('ـ', '');

  return normalized.trim();
}
