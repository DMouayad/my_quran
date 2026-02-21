import 'package:flutter/material.dart';
import 'package:my_quran/app/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key});

  static const String _currentVersion = '1.5.0'; // update per release
  static const String _seenKey = 'whats_new_seen_version';

  /// Call this on app startup. Shows dialog only once per version.
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          child: Column(
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Header icon ──
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 32,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Title ──
                      Text(
                        'ما الجديد؟',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الإصدار $_currentVersion',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Feature 1: Bookmark Categories ──
                      const _FeatureItem(
                        icon: Icons.bookmarks,
                        iconColor: Colors.orange,
                        title: 'تصنيفات العلامات المرجعية',
                        description:
                            'نظّم علاماتك المرجعية في تصنيفات مخصصة '
                            'بألوان مختلفة مثل: حفظ، مراجعة، تفسير، '
                            'أو أي تصنيف تختاره.',
                      ),
                      const SizedBox(height: 16),

                      // ── Feature 2: Notes ──
                      const _FeatureItem(
                        icon: Icons.edit_note,
                        iconColor: Colors.teal,
                        title: 'ملاحظات على الآيات',
                        description:
                            'أضف ملاحظاتك الخاصة على أي آية. '
                            'سجّل أفكارك وتأملاتك أثناء القراءة.',
                      ),
                      const SizedBox(height: 16),

                      // ── Feature 3: Visual Indicators ──
                      const _FeatureItem(
                        icon: Icons.visibility,
                        iconColor: Colors.purple,
                        title: 'مؤشرات بصرية',
                        description:
                            'يظهر لون التصنيف على رقم الآية. '
                            'وللآيات التي تحتوي ملاحظات يظهر خط أسفل الرقم.',
                      ),
                      const SizedBox(height: 16),

                      // ── How to use hint ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'اضغط مطولاً على أي آية لإضافة علامة أو ملاحظة.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.5,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              // ── Dismiss button ──
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('فهمت، شكراً'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.applyOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
