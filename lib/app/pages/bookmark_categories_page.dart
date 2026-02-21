import 'package:flutter/material.dart';

import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/bookmark_service.dart';
import 'package:my_quran/app/settings_controller.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({required this.settingsController, super.key});
  final SettingsController settingsController;

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _bookmarkService = BookmarkService();
  List<BookmarkCategory> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await _bookmarkService.getCategories();
    setState(() {
      _categories = cats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة التصنيفات')),
        floatingActionButton: FloatingActionButton(
          onPressed: _addCategory,
          child: const Icon(Icons.add),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _categories.isEmpty
            ? const Center(child: Text('لا توجد تصنيفات'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isDefault = cat.id == 'default';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cat.color,
                      radius: 16,
                    ),
                    title: Text(cat.title),
                    subtitle: isDefault
                        ? const Text('التصنيف الافتراضي')
                        : null,
                    trailing: isDefault
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _editCategory(cat),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                onPressed: () => _deleteCategory(cat),
                              ),
                            ],
                          ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _addCategory() async {
    final titleController = TextEditingController();
    const Color selectedColor = Colors.blue;

    final result = await showDialog<BookmarkCategory>(
      context: context,
      builder: (ctx) => _CategoryFormDialog(
        title: 'تصنيف جديد',
        titleController: titleController,
        initialColor: selectedColor,
        actionLabel: 'إنشاء',
      ),
    );

    if (result != null) {
      await _bookmarkService.addCategory(result);
      await _load();
    }
  }

  Future<void> _editCategory(BookmarkCategory cat) async {
    final titleController = TextEditingController(text: cat.title);

    final result = await showDialog<BookmarkCategory>(
      context: context,
      builder: (ctx) => _CategoryFormDialog(
        title: 'تعديل التصنيف',
        titleController: titleController,
        initialColor: cat.color,
        existingId: cat.id,
        actionLabel: 'حفظ',
      ),
    );

    if (result != null) {
      await _bookmarkService.updateCategory(result);
      await _load();
    }
  }

  Future<void> _deleteCategory(BookmarkCategory cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف التصنيف'),
          content: Text(
            'هل تريد حذف تصنيف "${cat.title}"؟\n'
            'سيتم نقل العلامات المرتبطة به إلى التصنيف الافتراضي.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed ?? false) {
      await _bookmarkService.removeCategory(cat.id);
      await _load();
    }
  }
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({
    required this.title,
    required this.titleController,
    required this.initialColor,
    required this.actionLabel,
    this.existingId,
  });

  final String title;
  final TextEditingController titleController;
  final Color initialColor;
  final String actionLabel;
  final String? existingId;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late Color _selectedColor;

  static const List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.brown,
    Colors.deepOrange,
    Colors.lime,
    Colors.lightBlue,
    Colors.deepPurple,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(widget.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: widget.titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'اسم التصنيف',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text('اللون'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 3,
                              )
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final title = widget.titleController.text.trim();
              if (title.isEmpty) return;
              final cat = BookmarkCategory(
                id:
                    widget.existingId ??
                    'cat_${DateTime.now().millisecondsSinceEpoch}',
                title: title,
                color: _selectedColor,
              );
              Navigator.pop(context, cat);
            },
            child: Text(widget.actionLabel),
          ),
        ],
      ),
    );
  }
}
