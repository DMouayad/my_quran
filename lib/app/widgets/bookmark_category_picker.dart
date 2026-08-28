import 'package:flutter/material.dart';
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/utils.dart';

enum BookmarkPickerAction { select, remove }

class BookmarkPickerResult {
  const BookmarkPickerResult.select(this.category)
    : action = BookmarkPickerAction.select;
  const BookmarkPickerResult.remove()
    : action = BookmarkPickerAction.remove,
      category = null;

  final BookmarkPickerAction action;
  final BookmarkCategory? category;
}

class BookmarkCategoryPicker extends StatelessWidget {
  const BookmarkCategoryPicker({
    required this.categories,
    required this.isBookmarked,
    required this.currentCategoryId,
    required this.showDragHandle,
    super.key,
  });

  final List<BookmarkCategory> categories;
  final bool isBookmarked;
  final String? currentCategoryId;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              dragHandle(colorScheme),
              Row(
                children: [
                  const Icon(Icons.bookmark, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isBookmarked ? 'تعديل العلامة' : 'إضافة علامة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  closeButton(context),
                ],
              ),
              const SizedBox(height: 12),

              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: categories.length + (isBookmarked ? 1 : 0),
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.applyOpacity(0.4),
                  ),
                  itemBuilder: (context, index) {
                    // Remove action (at bottom)
                    if (isBookmarked && index == categories.length) {
                      return ListTile(
                        leading: Icon(
                          Icons.bookmark_remove_outlined,
                          color: colorScheme.error,
                        ),
                        title: Text(
                          'إزالة العلامة',
                          style: TextStyle(color: colorScheme.error),
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          const BookmarkPickerResult.remove(),
                        ),
                      );
                    }

                    final cat = categories[index];
                    final isSelected =
                        isBookmarked && cat.id == currentCategoryId;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: cat.color,
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      title: Text(
                        cat.title,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: colorScheme.primary)
                          : null,
                      onTap: () => Navigator.pop(
                        context,
                        BookmarkPickerResult.select(cat),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget closeButton(BuildContext context) {
    if (showDragHandle) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.close, size: 20),
      onPressed: () => Navigator.pop(context),
    );
  }

  Widget dragHandle(ColorScheme colorScheme) {
    if (!showDragHandle) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
