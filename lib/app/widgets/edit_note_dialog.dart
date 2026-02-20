import 'package:flutter/material.dart';
import 'package:my_quran/app/models.dart';

Future<String?> showEditNoteDialog(
  BuildContext context,
  VerseBookmark? bookmark,
) async {
  final controller = TextEditingController(text: bookmark?.note ?? '');

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ملاحظة'),
              if (bookmark?.note?.isNotEmpty ?? false) ...[
                TextButton(
                  onPressed: () => Navigator.pop(ctx, ''),
                  child: Text(
                    'حذف الملاحظة',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
                ),
              ],
            ],
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'اكتب ملاحظتك هنا...',
              border: OutlineInputBorder(),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),

            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('حفظ'),
            ),
          ],
        ),
      );
    },
  );
}
