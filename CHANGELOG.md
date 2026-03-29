### 1.7.6

FEAT: improve changing scrolling mode.
FIX: ensure scrolled-to verse is visible (thanks to @Hy4ri). 
FEAT: highlight last reading-position verse.

### 1.7.5

FEAT: use package_info_plus to get the app version & build number.
FIX: update Github release workflow to fix Reproducible Build issue.  

### 1.7.2

FIX: app crash on web.

### 1.7.1

- FIX: Fixed dynamic color theming using device's accent color as seed for proper Material 3 color scheme generation.
- FEAT: add search match modes, improve search index and fix highlighting.
- FIX: dynamic color showing same surface for all elements (thanks to @Tid0lla).
- CI/CD: add support for building and publishing x86_64 Linux executables (thanks to @XxA7med66xX).

### 1.7.0

- FEAT: Improved the Settings sheet.
- FEAT: Added Sepia theme.
- FEAT: Added backup export/import for bookmarks and notes.
- FEAT: Notes are now independent from bookmarks and linked directly to verses.
- FEAT: Added dedicated Warsh page metadata.
- FIX: Fixed an issue where pages 488 - 489 is blank in Warsh narration.

### 1.6.0

- FIX: Fixed incorrect highlighting for exact-match words in search results.
- FEAT: Improved the colors in Light Reading Mode.
- FEAT: Improved the reading experience in landscape orientation.
- FEAT: Added an option to show the Hizb number in the page header.
- FEAT: Added an option to adjust line height.
- FEAT: Added a “Keep screen on while reading” feature.

### v1.5.0

- FEAT: Add bookmark categories with colors
- FEAT: Visual indicators on bookmarked verse numbers
- FEAT: New bookmarks screen with category filtering
- PERF: Page rendering performance improvements

### v1.4.3

- FIX: Navigation to a specific verse, surah, or page in Book Mode.
- FIX: Last reading position is now correctly restored when opening the app in Book Mode.
- FEAT: Keep the reading position when switching between Book Mode and list mode.

### v1.4.2

FEAT: add book mode
FEAT: add option for true-black background color
FIX: typo in Surah 7 verse 46

### v1.3.0

FEAT: add PWA support and deployment workflow
FEAT: cache page text, add verse menu dialog and improve verse highlighting
FEAT: add submit button to quick navigation dialog
FEAT: update launcher icons and generate web icons
FEAT: remove app bar glass effect
FIX: copied verse text font
FIX: font weight setting not applied
FIX: remove unnecessary gesture handling
PERF: optimize surah search dialog for empty search queries

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
