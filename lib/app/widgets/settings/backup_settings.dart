part of 'settings_screen.dart';

class BackupSettings extends StatelessWidget {
  const BackupSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsGroup(
          title: 'النسخ الاحتياطي',
          children: [
            _ActionRow(
              icon: Icons.upload_file,
              title: 'تصدير نسخة احتياطية',
              subtitle:
                  'مشاركة الملف — سيتم تنزيله تلقائياً إذا كانت المشاركة غير مدعومة',
              onTap: () async {
                await BackupService().exportAndShare();
              },
            ),
            _ActionRow(
              icon: Icons.download,
              title: 'استيراد نسخة احتياطية',
              subtitle: 'دمج مع البيانات الحالية أو استبدالها',
              onTap: () async {
                final backup = BackupService();
                final file = await backup.pickBackupFile();
                if (file == null) return;

                final preview = await backup.preview(file);
                if (!context.mounted) return;

                final mode = await showDialog<ImportMode>(
                  context: context,
                  builder: (ctx) {
                    return Directionality(
                      textDirection: TextDirection.rtl,
                      child: AlertDialog(
                        title: const Text('استيراد نسخة احتياطية'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('التاريخ: ${preview.createdAt}'),
                            const SizedBox(height: 8),
                            Text('التصنيفات: ${preview.categoryCount}'),
                            Text('العلامات: ${preview.bookmarkCount}'),
                            Text('الملاحظات: ${preview.noteCount}'),
                            const SizedBox(height: 12),
                            const Text('اختر طريقة الاستيراد:'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('إلغاء'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(ctx, ImportMode.merge),
                            child: const Text('دمج'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(ctx, ImportMode.replace),
                            child: const Text('استبدال'),
                          ),
                        ],
                      ),
                    );
                  },
                );

                if (mode == null) return;

                if (!context.mounted) return;
                unawaited(
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                );

                try {
                  await backup.import(file, mode: mode);
                  if (context.mounted) {
                    Navigator.pop(context); // close progress
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ تم الاستيراد بنجاح')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // close progress
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ فشل الاستيراد: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
