class ArabicTextProcessor {
  // Remove diacritics (tashkeel)
  static String removeDiacritics(String text) {
    return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  }

  // Normalize Arabic characters
  static String normalize(String text) {
    String normalized = removeDiacritics(text);

    // Normalize Alef variants: أ إ آ ا → ا
    normalized = normalized.replaceAll(RegExp('[أإآٱ]'), 'ا');

    // Normalize Taa Marbuta: ة → ه
    normalized = normalized.replaceAll('ة', 'ه');

    // Normalize Alef Maksura: ى → ي
    normalized = normalized.replaceAll('ى', 'ي');

    // Remove Tatweel (kashida)
    normalized = normalized.replaceAll('ـ', '');

    return normalized.trim();
  }

  // Tokenize Arabic text into words
  static List<String> tokenize(String text) {
    if (text.isEmpty) return [];

    // Remove punctuation and extra spaces
    // then split by whitespace and filter empty
    return text
        .replaceAll(
          RegExp(r'[\p{P}\p{S}\p{N}\-\(\)\[\]\{\}]+', unicode: true),
          ' ',
        )
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  // Get root variations for better search (optional - advanced)
  static List<String> getVariations(String word) {
    final variations = <String>[word];

    // Add version with/without ال (the definite article)
    if (word.startsWith('ال') && word.length > 2) {
      variations.add(word.substring(2));
    } else {
      variations.add('ال$word');
    }

    return variations;
  }
}
