### v1.2.5

FEAT: add hafs quran text and font
FIX: gaps between words for large font sizes (thanks to @Hy4ri)
FEAT: make navigation wheels items tapable
FEAT: implement quick navigation by tapping on surah, juz, and page number in the header

### v1.2.4

FIX: search, text sizer and navigation sheets are covered by on-screen navigation buttons
FEAT: add exact match search
FEAT: In search result card, implement text truncation for long verses to ensure the matching word is visible
REFACTOR: minify quran text json file
FEAT: reduce size of search index by removing duplications(word with diacritics)

### v1.2.3

- FIX: reproducible build is failing due to Flutter SDK mismatch

### v1.2.2

- FEAT: migrate to `SharedPreferencesAsync`
- FEAT: update home FAB and various styling
- FEAT: animate and center page indicator
- FIX: incorrect verse count in surah header

### v1.2.1

- build: update the release workflow to support reproducible builds on F-Droid

### v1.2.0

- FEAT(search): improve index generation and normalization logic
- FEAT: use glass effect for FAB
- FEAT: increase verseEndSymbol font size

### v1.1.0

- FEAT: a major redesign of the home page

### v1.0.1

- FEAT: add spacing for Dagger-Aleph in Quran text

### v1.0.0

- Initial release