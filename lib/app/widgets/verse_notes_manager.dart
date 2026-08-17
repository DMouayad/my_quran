import 'package:flutter/material.dart';
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/notes_service.dart';
import 'package:my_quran/app/utils.dart';
import 'package:my_quran/app/widgets/edit_note_dialog.dart';
import 'package:my_quran/quran/quran.dart';

class VerseNotesManager extends StatefulWidget {
  const VerseNotesManager({
    required this.surah,
    required this.verse,
    required this.onChanged,
    super.key,
  });

  final int surah;
  final int verse;
  final Future<void> Function() onChanged;

  @override
  State<VerseNotesManager> createState() => VerseNotesSheetState();
}

class VerseNotesSheetState extends State<VerseNotesManager> {
  final _notesService = NotesService();
  List<VerseNote> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notes = await _notesService.getNotesForVerse(
      widget.surah,
      widget.verse,
    );
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _addNote() async {
    final res = await showEditNoteDialog(context);
    if (res == null) return;
    if (res.action == NoteDialogAction.save) {
      await _notesService.addNote(
        surah: widget.surah,
        verse: widget.verse,
        text: res.text!,
      );
      await _load();
      await widget.onChanged();
    }
  }

  Future<void> _editNote(VerseNote note) async {
    final res = await showEditNoteDialog(
      context,
      initialText: note.text,
      canDelete: true,
    );
    if (res == null) return;

    if (res.action == NoteDialogAction.delete) {
      await _notesService.removeNoteById(note.id);
    } else {
      await _notesService.updateNote(note.copyWith(text: res.text));
    }

    await _load();
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final surahName = Quran.instance.getSurahNameArabic(widget.surah);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ملاحظات • سورة $surahName •'
                    ' الآية ${getArabicNumber(widget.verse)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                closeButton(context),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else ...[
              if (_notes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'لا توجد ملاحظات بعد',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _notes.length,
                    separatorBuilder: (_, _) => const Divider(height: 16),
                    itemBuilder: (context, i) {
                      final n = _notes[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(n.text),
                        subtitle: Text(
                          'آخر تعديل: ${n.updatedAt.year}/${n.updatedAt.month}/${n.updatedAt.day}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editNote(n),
                        ),
                        onTap: () => _editNote(n),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _addNote,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة ملاحظة'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget closeButton(BuildContext context) {
    if (isMobile) return const SizedBox.shrink();
    return IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.close),
    );
  }
}
