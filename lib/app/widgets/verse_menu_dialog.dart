import 'dart:async' show Timer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_quran/app/widgets/bookmark_category_picker.dart';

import 'package:my_quran/app/widgets/edit_note_dialog.dart';
import 'package:my_quran/app/widgets/overlay.dart';
import 'package:my_quran/app/widgets/verse_notes_sheet.dart';
import 'package:my_quran/quran/quran.dart';

import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/bookmark_service.dart';
import 'package:my_quran/app/services/notes_service.dart';
import 'package:my_quran/app/utils.dart';

class VerseMenuDialog extends StatefulWidget {
  const VerseMenuDialog({
    required this.fontFamily,
    required this.surah,
    required this.verse,
    required this.fontSize,
    super.key,
  });

  final int surah;
  final Verse verse;
  final FontFamily fontFamily;
  final double fontSize;

  @override
  State<VerseMenuDialog> createState() => _VerseMenuDialogState();
}

class _VerseMenuDialogState extends State<VerseMenuDialog> {
  late final bookmarkService = BookmarkService();
  late final notesService = NotesService();

  late bool isBookmarked = bookmarkService.isBookmarked(
    widget.surah,
    widget.verse.number,
  );

  late VerseBookmark? bookmark = bookmarkService.getBookmarkFor(
    widget.surah,
    widget.verse.number,
  );

  late final List<BookmarkCategory> categories = bookmarkService
      .getCategoriesSync();

  BookmarkCategory? currentCategory;

  // Notes state (verse-based)
  bool _notesLoading = true;
  List<VerseNote> _verseNotes = const [];

  bool get _hasNotes => _verseNotes.isNotEmpty;
  VerseNote? get _latestNote => _hasNotes ? _verseNotes.first : null;

  @override
  void initState() {
    super.initState();
    _syncCategory();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await notesService.getNotesForVerse(
      widget.surah,
      widget.verse.number,
    );
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (!mounted) return;
    setState(() {
      _verseNotes = notes;
      _notesLoading = false;
    });
  }

  void _syncCategory() {
    if (isBookmarked && bookmark?.categoryId != null) {
      try {
        currentCategory = categories.firstWhere(
          (c) => c.id == bookmark!.categoryId,
        );
      } catch (_) {
        currentCategory = null;
      }
    } else {
      currentCategory = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isLandscape = mq.orientation == Orientation.landscape;

    return SizedBox(
      width: isLandscape ? 560 : 340,
      height: isMobile ? mq.size.height * (isLandscape ? 0.9 : 0.6) : null,
      child: switch (isLandscape && isMobile) {
        true => _buildLandscapeBody(context),
        false => _buildPortraitBody(context),
      },
    );
  }

  Widget _buildPortraitBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: isMobile ? .spaceBetween : .start,
      children: [
        _buildHeader(context),
        Flexible(child: _buildVerseText(context, isLandscape: false)),
        if (!_notesLoading && _latestNote != null) _buildNotePreview(context),
        _buildActionButtons()
      ],
    );
  }

  Widget _buildLandscapeBody(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildVerseText(context, isLandscape: true),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildActionButtons(isLandscape: true),
                        const SizedBox(height: 12),
                        if (!_notesLoading && _latestNote != null)
                          _buildNotePreview(context, maxLines: 5),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerseText(BuildContext context, {required bool isLandscape}) {
    final colorScheme = Theme.of(context).colorScheme;

    final maxFont = isLandscape ? 32.0 : 40.0;
    final height = isLandscape ? 1.8 : 2.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Text(
        widget.verse.text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: widget.fontSize.clamp(16, maxFont),
          height: height,
          fontFamily: widget.fontFamily.name,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildActionButtons({bool isLandscape = false}) {
    if (isLandscape) {
      return _ActionButtons(
        isLandscape: true,
        currentCategory: currentCategory,
        isBookmarked: isBookmarked,
        hasNotes: _hasNotes,
        onCopyVerse: () => _copyVerse(context),
        onOpenBookmarkPicker: () => _openBookmarkPicker(context),
        onOpenNotes: () => _openNotes(context),
      );
    }
    return _ActionButtons(
      isLandscape: false,
      currentCategory: currentCategory,
      isBookmarked: isBookmarked,
      hasNotes: _hasNotes,
      onCopyVerse: () => _copyVerse(context),
      onOpenBookmarkPicker: () => _openBookmarkPicker(context),
      onOpenNotes: () => _openNotes(context),
    );
  }

  Widget _buildNotePreview(BuildContext context, {int maxLines = 2}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer.applyOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            right: BorderSide(
              color: colorScheme.tertiary.applyOpacity(0.5),
              width: 3,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.sticky_note_2_outlined,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _latestNote!.text,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBookmarkPicker(BuildContext context) async {
    final result = await showOverlay<BookmarkPickerResult>(
      context,
      widget: BookmarkCategoryPicker(
        categories: categories,
        isBookmarked: isBookmarked,
        currentCategoryId: bookmark?.categoryId,
        showDragHandle: isMobile,
      ),
      mobileConfig: const MobileOverlayConfig(
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: false, // we already show a handle
      ),
      desktopConfig: const DesktopOverlayConfig(
        constraints: BoxConstraints(maxWidth: 500),
      ),
    );

    if (result == null) return;

    if (result.action == BookmarkPickerAction.remove) {
      await _onRemoveBookmark(context);
      return;
    }

    final cat = result.category!;
    // If it's already selected, do nothing
    if (isBookmarked && bookmark?.categoryId == cat.id) return;

    await _onCategorySelected(context, cat);
  }
  // ─────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          const SizedBox(width: 18),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.menu_book,
              size: 18,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DefaultTextStyle(
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              child: Row(
                children: [
                  Text(Quran.instance.getSurahNameArabic(widget.surah)),
                  const Text(' - '),
                  const Text('الآية '),
                  Text(
                    getArabicNumber(widget.verse.number),
                    style: TextStyle(
                      fontFamily: FontFamily.arabicNumbersFontFamily.name,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────

  Future<void> _onCategorySelected(
    BuildContext context,
    BookmarkCategory cat,
  ) async {
    if (isBookmarked) {
      final updated = bookmark!.copyWith(categoryId: () => cat.id);
      await bookmarkService.updateBookmark(updated);
      setState(() {
        bookmark = updated;
        _syncCategory();
      });
    } else {
      final newBookmark = VerseBookmark(
        id:
            '${widget.surah}_${widget.verse.number}_'
            '${DateTime.now().millisecondsSinceEpoch}',
        surah: widget.surah,
        verse: widget.verse.number,
        pageNumber: Quran.instance.getPageNumber(
          widget.surah,
          widget.verse.number,
        ),
        createdAt: DateTime.now(),
        categoryId: cat.id,
      );

      await bookmarkService.addBookmark(newBookmark);
      setState(() {
        isBookmarked = true;
        bookmark = newBookmark;
        _syncCategory();
      });
    }
  }

  Future<void> _onRemoveBookmark(BuildContext context) async {
    await bookmarkService.removeBookmarkByVerse(
      widget.surah,
      widget.verse.number,
    );
    setState(() {
      isBookmarked = false;
      bookmark = null;
      currentCategory = null;
    });
  }

  Future<void> _openNotes(BuildContext context) async {
    if (_verseNotes.isEmpty) {
      // 0 notes: quick add
      final res = await showEditNoteDialog(context);
      if (res == null || res.action != NoteDialogAction.save) return;

      await notesService.addNote(
        surah: widget.surah,
        verse: widget.verse.number,
        text: res.text!,
      );

      await _loadNotes();
      return;
    }

    // 1+ notes: open manager sheet (add/edit/delete)
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: VerseNotesSheet(
          surah: widget.surah,
          verse: widget.verse.number,
          onChanged: _loadNotes,
        ),
      ),
    );
  }

  void _copyVerse(BuildContext context) {
    final surahName = Quran.instance.getSurahNameArabic(widget.surah);
    final verseInPlainText = Quran.instance.getVerseInPlainText(
      widget.surah,
      widget.verse.number,
    );
    final textToCopy =
        'سورة $surahName - الآية {${getArabicNumber(widget.verse.number)}}\n'
        '"$verseInPlainText"\n';
    Clipboard.setData(ClipboardData(text: textToCopy));
  }
}

// ─────────────────────────────────────────────────────────
// Action buttons
// ─────────────────────────────────────────────────────────
enum _Action {
  copy,
  bookmark,
  notes,
}

typedef _ActionButton = ({
  _Action action,
  String label,
  IconData icon,
  VoidCallback onTap,
  bool isClicked
});

class _ActionButtons extends StatefulWidget {
  const _ActionButtons({
    required this.isLandscape,
    required this.isBookmarked,
    required this.hasNotes,
    required this.onCopyVerse,
    required this.onOpenBookmarkPicker,
    required this.onOpenNotes,
    required this.currentCategory,
  });

  final bool isLandscape;
  final bool isBookmarked;
  final bool hasNotes;
  final VoidCallback onCopyVerse;
  final VoidCallback onOpenBookmarkPicker;
  final VoidCallback onOpenNotes;
  final BookmarkCategory? currentCategory;

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  bool _isCopied = false;
  Timer? _copyTimer;

  List<_ActionButton> get buttons => [
    (
      action: _Action.copy,
      icon: _isCopied ? Icons.check_circle : Icons.copy,
      label: _isCopied ? 'تم النسخ' : 'نسخ الآية',
      onTap: _handleCopyButtonTap,
      isClicked: _isCopied,
    ),
    (
      action: _Action.bookmark,
      icon: widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
      label: widget.isBookmarked ? 'تعديل العلامة' : 'إضافة علامة',
      onTap: widget.onOpenBookmarkPicker,
      isClicked: widget.isBookmarked,
    ),
    (
      action: _Action.notes,
      icon: widget.hasNotes ? Icons.edit_note : Icons.note_add_outlined,
      label: 'ملاحظات',
      onTap: widget.onOpenNotes,
      isClicked: false,
    ),
  ];

  void _handleCopyButtonTap() {
    _copyTimer?.cancel();
    setState(() => _isCopied = true);

    widget.onCopyVerse();

    _copyTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isCopied = false);
    });
  }

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.isLandscape) {
      return Column(
        children: buttons
            .map((button) => _landscapeButtonLayout(colorScheme, button))
            .toList(),
      );
    } else {
      return Row(
        children: buttons.map((button) => Expanded(
            child: _portraitButtonLayout(context, colorScheme, button),
          )).toList(),
      );
    }
  }

  Widget _portraitButtonLayout(
    BuildContext context,
    ColorScheme colorScheme,
    _ActionButton button,
  ) {
    final bool isClicked = button.isClicked;

    return ListTile(
      onTap: button.onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.only(
          bottomRight: button == buttons.first
              ? const Radius.circular(16)
              : Radius.zero,
          bottomLeft: button == buttons.last
              ? const Radius.circular(16)
              : Radius.zero,
        ),
      ),
      tileColor: colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      // Better font clarity on desktop/web.
      dense: !(isDesktop || kIsWeb),
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          _PopupSwitcher(
            childKey: button.icon,
            child: _buildIcon(
              button: button,
              isClicked: isClicked,
              colorScheme: colorScheme,
            ),
          ),
          Text(button.label, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _landscapeButtonLayout(ColorScheme colorScheme, _ActionButton button) {
    final bool isClicked = button.isClicked;

    return ListTile(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.all(Radius.circular(5)),
      ),
      contentPadding: EdgeInsets.zero,
      leading: _PopupSwitcher(
        childKey: button.icon,
        child: _buildIcon(
          button: button,
          isClicked: isClicked,
          colorScheme: colorScheme,
        ),
      ),
      title: Text(button.label),
      onTap: button.onTap,
      dense: true,
    );
  }

  Widget _buildIcon({
    required _ActionButton button,
    required bool isClicked,
    required ColorScheme colorScheme,
    double? size,
  }) {
    return Icon(
      button.icon,
      size: size,
      color: button.action == _Action.bookmark && isClicked
          ? widget.currentCategory?.color
          : isClicked
          ? colorScheme.primary
          : null,
    );
  }
}

class _PopupSwitcher extends StatelessWidget {
  const _PopupSwitcher({
    required this.child,
    required this.childKey,
  });

  final Widget child;
  final Object childKey;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(childKey),
        child: child,
      ),
    );
  }
}
