// ignore_for_file: avoid_print (),
// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

void main() {
  final projectRoot = _findProjectRoot();
  if (projectRoot == null) {
    stderr.writeln('❌ Could not find project root (no pubspec.yaml found)');
    exit(1);
  }

  final version = _readVersion(projectRoot);
  if (version == null) {
    stderr.writeln('❌ Could not read version from pubspec.yaml');
    exit(1);
  }

  final buildNumber = _readBuildNumber(projectRoot);
  print('📦 Version: $version (build $buildNumber)');

  final versionMap = _readVersionMap(projectRoot);

  // Ensure current version is in the map
  if (buildNumber != null && !versionMap.containsKey(buildNumber)) {
    print('⚠️  Build $buildNumber not in version_map.txt, adding it.');
    versionMap[buildNumber] = version;
    _writeVersionMap(projectRoot, versionMap);
  }

  final allVersions = _readAllChangelogs(projectRoot, versionMap, buildNumber);
  if (allVersions.isEmpty) {
    stderr.writeln('❌ No changelog files found');
    exit(1);
  }

  print('📝 Found ${allVersions.length} version(s):');
  for (final v in allVersions) {
    final tag = v.isCurrent ? ' ← current' : '';
    final total = v.entries.length;
    final grouped = _groupByCategory(v.entries);
    final groupsCount = grouped.keys.length;
    print(
      '   v${v.version} (build ${v.buildNumber}, $total entries, $groupsCount groups)$tag',
    );
  }

  final success = _updateDialogFile(projectRoot, version, allVersions);
  if (success) {
    print('✅ Updated whats_new_dialog.dart');
  } else {
    stderr.writeln('❌ Failed to update whats_new_dialog.dart');
    exit(1);
  }
}

// ─────────────────────────────────────────────────────────
// Project helpers
// ─────────────────────────────────────────────────────────

String? _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

String? _readVersion(String root) {
  final file = File('$root/pubspec.yaml');
  if (!file.existsSync()) return null;
  for (final line in file.readAsLinesSync()) {
    final match = RegExp(r'^version:\s*(\S+)').firstMatch(line);
    if (match != null) return match.group(1)!.split('+').first;
  }
  return null;
}

int? _readBuildNumber(String root, {String abi = 'arm64-v8a'}) {
  final file = File('$root/pubspec.yaml');
  if (!file.existsSync()) return null;

  final abiVersionCode = switch (abi) {
    'x86_64' => 1,
    'armeabi-v7a' => 2,
    'arm64-v8a' => 3,
    _ => 0,
  };

  for (final line in file.readAsLinesSync()) {
    final match = RegExp(r'^version:\s*\S+\+(\d+)').firstMatch(line);
    if (match == null) continue;

    final baseBuildNumber = int.tryParse(match.group(1)!);
    if (baseBuildNumber == null) return null;

    return baseBuildNumber * 10 + abiVersionCode;
  }

  return null;
}

// ─────────────────────────────────────────────────────────
// Version map
// ─────────────────────────────────────────────────────────

Map<int, String> _readVersionMap(String root) {
  final file = File('$root/fastlane/version_map.txt');
  if (!file.existsSync()) {
    print('📄 No version_map.txt found, creating one.');
    return {};
  }

  final map = <int, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final parts = trimmed.split('=');
    if (parts.length == 2) {
      final num = int.tryParse(parts[0].trim());
      if (num != null) map[num] = parts[1].trim();
    }
  }
  return map;
}

void _writeVersionMap(String root, Map<int, String> map) {
  final file = File('$root/fastlane/version_map.txt');
  final sorted = map.keys.toList()..sort();
  final lines = <String>[
    '# build_number=version',
    for (final key in sorted) '$key=${map[key]}',
  ];
  file.writeAsStringSync('${lines.join('\n')}\n');
  print('📄 Updated version_map.txt');
}

// ─────────────────────────────────────────────────────────
// Categories (icon+color belong to category)
// ─────────────────────────────────────────────────────────

class _CategoryDef {
  const _CategoryDef({
    required this.id,
    required this.titleAr,
    required this.icon,
    required this.color,
    required this.keywords,
  });

  final String id;
  final String titleAr; // dialog is RTL/Arabic in your generated file
  final String icon; // Dart code string e.g. Icons.bug_report
  final String color; // Dart code string e.g. Colors.red
  final List<String> keywords;
}

const _categories = <_CategoryDef>[
  _CategoryDef(
    id: 'fix',
    titleAr: 'الإصلاحات',
    icon: 'Icons.bug_report',
    color: 'Colors.red',
    keywords: ['fix', 'bug', 'crash', 'إصلاح', 'مشكلة', 'عطل'],
  ),
  _CategoryDef(
    id: 'feature',
    titleAr: 'ميزات جديدة',
    icon: 'Icons.new_releases',
    color: 'Colors.green',
    keywords: [
      // EN
      'new feature',
      'feature',
      'added',
      'add ',
      'introduc', // matches introduce/introduced/introducing
      'now supports',
      'support for',
      'enable',
      // AR
      'ميزة',
      'ميزات',
      'ميزة جديدة',
      'جديد',
      'جديدة',
      'تمت إضافة',
      'إضافة',
      'يدعم',
      'دعم',
      'إتاحة',
    ],
  ),
  _CategoryDef(
    id: 'performance',
    titleAr: 'الأداء',
    icon: 'Icons.speed',
    color: 'Colors.indigo',
    keywords: ['performance', 'speed', 'أداء', 'سرعة', 'بطء'],
  ),
  _CategoryDef(
    id: 'improvement',
    titleAr: 'التحسينات',
    icon: 'Icons.trending_up',
    color: 'Colors.blue',
    keywords: ['improve', 'improvement', 'enhance', 'تحسين', 'تطوير'],
  ),
  _CategoryDef(
    id: 'search',
    titleAr: 'البحث',
    icon: 'Icons.search',
    color: 'Colors.blueGrey',
    keywords: ['search', 'query', 'بحث', 'استعلام'],
  ),
  _CategoryDef(
    id: 'ui',
    titleAr: 'واجهة المستخدم',
    icon: 'Icons.palette',
    color: 'Colors.purple',
    keywords: ['theme', 'dark', 'ui', 'مظهر', 'سمة', 'واجهة', 'screen', 'شاشة'],
  ),
  _CategoryDef(
    id: 'bookmark',
    titleAr: 'العلامات',
    icon: 'Icons.bookmarks',
    color: 'Colors.orange',
    keywords: ['bookmark', 'bookmarks', 'علامة', 'مرجعية'],
  ),
  _CategoryDef(
    id: 'note',
    titleAr: 'الملاحظات',
    icon: 'Icons.edit_note',
    color: 'Colors.teal',
    keywords: ['note', 'notes', 'ملاحظ', 'ملاحظة', 'ملاحظات'],
  ),
  _CategoryDef(
    id: 'other',
    titleAr: 'أخرى',
    icon: 'Icons.auto_awesome',
    color: 'Colors.blueGrey',
    keywords: [],
  ),
  _CategoryDef(
    id: 'text',
    titleAr: 'النص والخطوط',
    icon: 'Icons.text_fields',
    color: 'Colors.deepOrange',
    keywords: [
      'font',
      'text',
      'glyph',
      'mushaf',
      'render',
      'warsh',
      'hafs',
      'خط',
      'نص',
      'مصحف',
      'رسم',
      'ورش',
      'حفص',
    ],
  ),
];

const _categoryOrder = <String>[
  'fix',
  'feature',
  'performance',
  'improvement',
  'search',
  'ui',
  'bookmark',
  'note',
  'other',
];

_CategoryDef _categoryById(String id) =>
    _categories.firstWhere((c) => c.id == id, orElse: () => _categories.last);

// (#3) Normalize before keyword matching
String _normalizeForGuessing(String s) {
  var normalized = s.toLowerCase();

  // Remove common Arabic diacritics (plus dagger alif)
  normalized = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

  // Remove Quran annotation marks just in case
  normalized = s.replaceAll(RegExp(r'[\u06D6-\u06ED\u08D3-\u08FF\u06DD]'), '');

  // Fold some Arabic variants for matching
  normalized = s
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه');

  // Replace punctuation/symbols with spaces
  normalized = s.replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF\s]+'), ' ');

  // Collapse whitespace
  normalized = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return normalized;
}

String _guessCategoryId(String text) {
  final norm = _normalizeForGuessing(text);
  for (final c in _categories) {
    if (c.keywords.any(norm.contains)) return c.id;
  }
  return 'other';
}

Map<String, List<_ChangelogEntry>> _groupByCategory(
  List<_ChangelogEntry> items,
) {
  final map = <String, List<_ChangelogEntry>>{};
  for (final e in items) {
    map.putIfAbsent(e.categoryId, () => []).add(e);
  }
  return map;
}

// ─────────────────────────────────────────────────────────
// Changelog reading
// ─────────────────────────────────────────────────────────

List<_VersionChangelog> _readAllChangelogs(
  String root,
  Map<int, String> versionMap,
  int? currentBuild,
) {
  final dirs = [
    '$root/fastlane/metadata/android/ar/changelogs',
    '$root/fastlane/metadata/android/ar-SA/changelogs',
    '$root/fastlane/metadata/android/en-US/changelogs',
  ];

  Directory? changelogDir;
  for (final path in dirs) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      changelogDir = dir;
      print('📄 Reading from: $path');
      break;
    }
  }
  if (changelogDir == null) return [];

  final files =
      changelogDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.txt'))
          .toList()
        ..sort((a, b) {
          final aNum = _extractBuildNumber(a.path) ?? 0;
          final bNum = _extractBuildNumber(b.path) ?? 0;
          return bNum.compareTo(aNum);
        });

  final versions = <_VersionChangelog>[];

  for (final file in files) {
    final buildNum = _extractBuildNumber(file.path);
    if (buildNum == null) continue;

    final content = file.readAsStringSync().trim();
    if (content.isEmpty) continue;

    final entries = _parseChangelog(content);
    if (entries.isEmpty) continue;

    final isCurrent = buildNum == currentBuild;
    final version = versionMap[buildNum] ?? buildNum.toString();

    _warnChangelogQuality(buildNum, version, entries);

    versions.add(
      _VersionChangelog(
        version: version,
        buildNumber: buildNum,
        isCurrent: isCurrent,
        entries: entries,
      ),
    );
  }

  // Deterministic safety (#1)
  versions.sort((a, b) => b.buildNumber.compareTo(a.buildNumber));
  print(versions.toList());
  // Safety: if nothing matched as current, mark first
  if (versions.isNotEmpty && !versions.any((v) => v.isCurrent)) {
    print(
      '⚠️  No build matched current ($currentBuild). Marking newest as current.',
    );
    final first = versions.first;
    versions[0] = _VersionChangelog(
      version: versionMap[first.buildNumber] ?? first.version,
      buildNumber: first.buildNumber,
      isCurrent: true,
      entries: first.entries,
    );
  }

  return versions;
}

int? _extractBuildNumber(String path) {
  final fileName = path.split(Platform.pathSeparator).last;
  final match = RegExp(r'^(\d+)\.txt$').firstMatch(fileName);
  return match != null ? int.tryParse(match.group(1)!) : null;
}

List<_ChangelogEntry> _parseChangelog(String content) {
  final entries = <_ChangelogEntry>[];

  for (var line in content.split('\n')) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    final bulletMatch = RegExp(r'^[-*•]\s+(.+)$').firstMatch(line);
    final text = bulletMatch?.group(1)?.trim() ?? line;

    entries.add(
      _ChangelogEntry(text: text, categoryId: _guessCategoryId(text)),
    );
  }

  return entries;
}

// ─────────────────────────────────────────────────────────
// Warnings / quality checks (#7)
// ─────────────────────────────────────────────────────────

void _warnChangelogQuality(
  int buildNum,
  String version,
  List<_ChangelogEntry> entries,
) {
  if (entries.isEmpty) return;

  // Long line warning
  const maxLen = 140;
  for (final e in entries) {
    if (e.text.length > maxLen) {
      final preview = e.text.substring(0, maxLen);
      print(
        '⚠️  Long changelog line (v$version build $buildNum, ${e.text.length} chars): "$preview..."',
      );
      break;
    }
  }

  // Duplicate warning
  final seen = <String>{};
  final dups = <String>[];
  for (final e in entries) {
    final key = e.text.trim();
    if (!seen.add(key)) dups.add(key);
  }
  if (dups.isNotEmpty) {
    print(
      '⚠️  Duplicate changelog entries (v$version build $buildNum): ${dups.take(3).toList()}'
      '${dups.length > 3 ? ' (+${dups.length - 3} more)' : ''}',
    );
  }

  // Too many "other" warning (signals weak keyword set)
  final otherCount = entries.where((e) => e.categoryId == 'other').length;
  final ratio = otherCount / entries.length;
  if (ratio >= 0.7) {
    print(
      '⚠️  Many entries fell into category "other" for v$version build $buildNum '
      '($otherCount/${entries.length}). Consider expanding category keywords.',
    );
  }
}

// ─────────────────────────────────────────────────────────
// Code generation
// ─────────────────────────────────────────────────────────

bool _updateDialogFile(
  String root,
  String currentVersion,
  List<_VersionChangelog> allVersions,
) {
  final filePath = '$root/lib/app/widgets/whats_new_dialog.dart';
  final content = _generateDialogCode(currentVersion, allVersions);

  final file = File(filePath);
  final old = file.existsSync() ? file.readAsStringSync() : null;

  // Deterministic + avoid rewriting when unchanged (#1)
  if (old == content) {
    print('ℹ️  whats_new_dialog.dart unchanged');
    return true;
  }

  file.writeAsStringSync(content);
  return true;
}

String _generateDialogCode(
  String currentVersion,
  List<_VersionChangelog> allVersions,
) {
  final versionWidgets = StringBuffer();

  for (final ver in allVersions) {
    // Group entries by category
    final grouped = _groupByCategory(ver.entries);

    versionWidgets.writeln('                      _VersionSection(');
    versionWidgets.writeln(
      "                        version: '${_esc(ver.version)}',",
    );
    versionWidgets.writeln(
      '                        isCurrent: ${ver.isCurrent},',
    );

    versionWidgets.writeln('                        categories: [');

    for (final catId in _categoryOrder) {
      final items = grouped[catId];
      if (items == null || items.isEmpty) continue;

      final def = _categoryById(catId);

      versionWidgets.writeln('                          _CategorySection(');
      versionWidgets.writeln(
        "                            title: '${_esc(def.titleAr)}',",
      );
      versionWidgets.writeln('                            icon: ${def.icon},');
      versionWidgets.writeln(
        '                            color: ${def.color},',
      );
      versionWidgets.writeln('                            items: [');

      for (final item in items) {
        versionWidgets.writeln(
          "                              '${_esc(item.text)}',",
        );
      }

      versionWidgets.writeln('                            ],');
      versionWidgets.writeln('                          ),');
    }

    versionWidgets.writeln('                        ],');
    versionWidgets.writeln('                      ),');
  }

  return '''
// GENERATED — DO NOT EDIT BY HAND
// Run: dart run scripts/update_whats_new.dart
// Version: $currentVersion

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore_for_file: lines_longer_than_80_chars ()

class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key});

  static const String _currentVersion = '$currentVersion';
  static const String _seenKey = 'whats_new_seen_version';

  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final seenVersion = prefs.getString(_seenKey);
    if (seenVersion == _currentVersion) return;
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const WhatsNewDialog(),
    );

    await prefs.setString(_seenKey, _currentVersion);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 28,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ما الجديد؟',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
$versionWidgets
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('فهمت، شكراً'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionSection extends StatelessWidget {
  const _VersionSection({
    required this.version,
    required this.isCurrent,
    required this.categories,
  });

  final String version;
  final bool isCurrent;
  final List<_CategorySection> categories;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ExpansionTile(
        key: isCurrent ? const Key('current_version') : null,
        initiallyExpanded: isCurrent,
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Text(
              'v\$version',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'الحالي',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ],
        ),
        children: [
          for (final cat in categories) cat,
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final t in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: textTheme.bodyMedium),
                  Expanded(
                    child: Text(
                      t,
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
''';
}

String _esc(String s) {
  return s
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll('\n', r'\n')
      .replaceAll(r'$', r'\$');
}

// ─────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────

class _ChangelogEntry {
  const _ChangelogEntry({required this.text, required this.categoryId});

  final String text;
  final String categoryId;
}

class _VersionChangelog {
  const _VersionChangelog({
    required this.version,
    required this.buildNumber,
    required this.isCurrent,
    required this.entries,
  });

  final String version;
  final int buildNumber;
  final bool isCurrent;
  final List<_ChangelogEntry> entries;

  @override
  String toString() {
    return '_VersionChangelog($version, $buildNumber)';
  }
}
