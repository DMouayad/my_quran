class ArabicTextProcessor {
  // A minimal, correct map to handle common typing shortcuts.
  static const Map<String, String> _spellVariants = {
    'الرحمن': 'الرحمان',
    'هذا': 'هاذا',
    'ذلك': 'ذالك',
    'ذلكم': 'ذالكم',
    'لكن': 'لاكن',
    'إله': 'إلاه',
    'اله': 'الاه',
    'السلام': 'السلام',
    'اسرائيل': 'اسراءيل',
    'اسحق': 'اسحاق',
    'اسمعيل': 'اسماعيل',
    'صرط': 'صراط',
  };

  // Remove diacritics (tashkeel)
  static String removeDiacritics(String text) {
    // Convert dagger alef to standard alef for consistency.
    final updated = text.replaceAll('\u0670', 'ا');
    return updated.replaceAll(
      RegExp(r'[\u0610-\u061A\u064B-\u065F\u06D6-\u06ED]'),
      '',
    );
  }

  // Normalize Arabic characters
  static String normalize(String text) {
    // Apply special spelling variants first for user-typed queries.
    String normalized = _spellVariants[text] ?? text;

    // Remove punctuation and symbols
    normalized = normalized.replaceAll(
      RegExp(r'[\p{P}\p{S}\p{N}\-\(\)\[\]\{\}]+', unicode: true),
      '',
    );
    normalized = removeDiacritics(normalized);

    // Normalize Alef variants: أ إ آ ا → ا
    normalized = normalized.replaceAll(RegExp('[أإآٱ]'), 'ا');

    // Normalize Taa Marbuta: ة → ه
    normalized = normalized.replaceAll('ة', 'ه');

    // Normalize Alef Maksura: ى → ي
    normalized = normalized.replaceAll('ى', 'ي');

    // Normalize Hamza forms
    normalized = normalized.replaceAll('ؤ', 'و');
    normalized = normalized.replaceAll('ئ', 'ء');
    normalized = normalized.replaceAll('ء', '');

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
}
