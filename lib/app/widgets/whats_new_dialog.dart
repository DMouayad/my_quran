// GENERATED — DO NOT EDIT BY HAND
// Run: dart run scripts/update_whats_new.dart
// Version: 1.7.6

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore_for_file: lines_longer_than_80_chars ()

class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key});

  static const String _currentVersion = '1.7.6';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      style: Theme.of(context).textTheme.headlineSmall
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
                      _VersionSection(
                        version: '1.7.6',
                        isCurrent: true,
                        categories: [
                          _CategorySection(
                            title: 'الإصلاحات',
                            icon: Icons.bug_report,
                            color: Colors.red,
                            items: [
                              'إصلاح مشكلة عدم ظهور الآية بشكل كامل بعد الانتقال إليها.',
                            ],
                          ),
                          _CategorySection(
                            title: 'التحسينات',
                            icon: Icons.trending_up,
                            color: Colors.blue,
                            items: [
                              'تم تحسين التبديل بين وضع الكتاب والتمرير العمودي لتجربة أكثر سلاسة.',
                            ],
                          ),
                          _CategorySection(
                            title: 'أخرى',
                            icon: Icons.auto_awesome,
                            color: Colors.blueGrey,
                            items: ['تظليل الآية عند استعادة آخر موضع قراءة.'],
                          ),
                        ],
                      ),
                      _VersionSection(
                        version: '1.7.5',
                        isCurrent: false,
                        categories: [
                          _CategorySection(
                            title: 'الإصلاحات',
                            icon: Icons.bug_report,
                            color: Colors.red,
                            items: [
                              'إصلاح مشكلة الصفحتين 488 - 489 في رواية ورش',
                              'إصلاح مشكلة ظهور نتائج البحث بدون تظليل الكلمة المطابقة.',
                              'إصلاح مشكلة في مظهر ألوان الجهاز (Dynamic) كانت تجعل معظم الأسطح تستخدم نفس لون.',
                              'إصلاح تعطل تطبيق الويب',
                            ],
                          ),
                          _CategorySection(
                            title: 'ميزات جديدة',
                            icon: Icons.new_releases,
                            color: Colors.green,
                            items: [
                              'إضافة ميزة النسخ الاحتياطي والاستيراد للعلامات المرجعية والملاحظات.',
                              'إضافة مظهر جديد سيبيا (Sepia).',
                              'إضافة خيارات مطابقة متعددة للبحث (تلقائي/مطابق/بداية الكلمة/داخل الكلمة/مرن).',
                            ],
                          ),
                          _CategorySection(
                            title: 'الأداء',
                            icon: Icons.speed,
                            color: Colors.indigo,
                            items: ['تحسينات طفيفة في الأداء والاستقرار.'],
                          ),
                          _CategorySection(
                            title: 'التحسينات',
                            icon: Icons.trending_up,
                            color: Colors.blue,
                            items: [
                              'تحسين صفحة الإعدادات.',
                              'تحسين البحث ليعطي نتائج أكثر دقة عند كتابة حرفين أو أكثر.',
                            ],
                          ),
                          _CategorySection(
                            title: 'العلامات',
                            icon: Icons.bookmarks,
                            color: Colors.orange,
                            items: [
                              'فصل الملاحظات عن العلامات المرجعية لتصبح مرتبطة بالآية مباشرة.',
                            ],
                          ),
                        ],
                      ),
                      _VersionSection(
                        version: '1.6.0',
                        isCurrent: false,
                        categories: [
                          _CategorySection(
                            title: 'الإصلاحات',
                            icon: Icons.bug_report,
                            color: Colors.red,
                            items: [
                              'إصلاح مشكلة التظليل في نتائج البحث للكلمات المطابقة',
                            ],
                          ),
                          _CategorySection(
                            title: 'ميزات جديدة',
                            icon: Icons.new_releases,
                            color: Colors.green,
                            items: [
                              'إضافة خيار عرض رقم الحزب في رأس الصفحة',
                              'إضافة خيار لتغيير ارتفاع الأسطر',
                              'إضافة ميزة إبقاء الشاشة مضاءة أثناء القراءة',
                              'دعم Material You (استخدام الوان الجهاز في التطبيق)',
                            ],
                          ),
                          _CategorySection(
                            title: 'التحسينات',
                            icon: Icons.trending_up,
                            color: Colors.blue,
                            items: [
                              'تحسين ألوان وضع القراءة الفاتح',
                              'تحسين تجربة القراءة في الوضع الأفقي',
                            ],
                          ),
                        ],
                      ),
                      _VersionSection(
                        version: '1.5.0',
                        isCurrent: false,
                        categories: [
                          _CategorySection(
                            title: 'ميزات جديدة',
                            icon: Icons.new_releases,
                            color: Colors.green,
                            items: [
                              'نظام علامات مرجعية جديد مع تصنيفات وألوان قابلة للتخصيص',
                            ],
                          ),
                          _CategorySection(
                            title: 'واجهة المستخدم',
                            icon: Icons.palette,
                            color: Colors.purple,
                            items: [
                              'شاشة مخصصة لعرض وتصفية العلامات حسب التصنيف',
                            ],
                          ),
                          _CategorySection(
                            title: 'الملاحظات',
                            icon: Icons.edit_note,
                            color: Colors.teal,
                            items: [
                              'أرقام الآيات المحفوظة تظهر الآن بلون التصنيف مع تمييز الملاحظات',
                            ],
                          ),
                          _CategorySection(
                            title: 'أخرى',
                            icon: Icons.auto_awesome,
                            color: Colors.blueGrey,
                            items: [
                              'إعادة تصميم قائمة الآية لتجربة أسرع وأبسط',
                            ],
                          ),
                        ],
                      ),
                      _VersionSection(
                        version: '1.4.4',
                        isCurrent: false,
                        categories: [
                          _CategorySection(
                            title: 'ميزات جديدة',
                            icon: Icons.new_releases,
                            color: Colors.green,
                            items: [
                              'رواية ورش عن نافع: دعم كامل لرواية ورش بالرسم العثماني المخصص، مع ضبط فواصل الآيات والترقيم الخاص بالرواية.',
                            ],
                          ),
                        ],
                      ),
                      _VersionSection(
                        version: '1.4.3',
                        isCurrent: false,
                        categories: [
                          _CategorySection(
                            title: 'الإصلاحات',
                            icon: Icons.bug_report,
                            color: Colors.red,
                            items: [
                              'إصلاح: الانتقال إلى آية أو سورة أو صفحة معينة في وضع الكتاب.',
                              'إصلاح: استعادة آخر موضع قراءة الآن بشكل صحيح عند فتح التطبيق في وضع الكتاب.',
                            ],
                          ),
                          _CategorySection(
                            title: 'ميزات جديدة',
                            icon: Icons.new_releases,
                            color: Colors.green,
                            items: [
                              'ميزة: الحفاظ على موضع القراءة عند التبديل بين وضع الكتاب والوضع العادي.',
                            ],
                          ),
                        ],
                      ),
                      _VersionSection(
                        version: '1.4.2',
                        isCurrent: false,
                        categories: [
                          _CategorySection(
                            title: 'الإصلاحات',
                            icon: Icons.bug_report,
                            color: Colors.red,
                            items: [
                              'إصلاح: خطأ إملائي في الآية 46 من سورة الأعراف.',
                            ],
                          ),
                          _CategorySection(
                            title: 'ميزات جديدة',
                            icon: Icons.new_releases,
                            color: Colors.green,
                            items: [
                              'إضافة وضع الكتاب للتنقل بين الصفحات بالسحب.',
                              'إضافة خيار اللون الأسود الحقيقي لشاشات OLED.',
                            ],
                          ),
                        ],
                      ),
                      _VersionSection(
                        version: '1.3.0',
                        isCurrent: false,
                        categories: [
                          _CategorySection(
                            title: 'الإصلاحات',
                            icon: Icons.bug_report,
                            color: Colors.red,
                            items: [
                              'إصلاح مشكلة عدم تطبيق إعدادات سماكة الخط.',
                              'إصلاح مشكلة الخط في النصوص المنسوخة.',
                            ],
                          ),
                          _CategorySection(
                            title: 'ميزات جديدة',
                            icon: Icons.new_releases,
                            color: Colors.green,
                            items: [
                              'إضافة زر "انتقال" لتسهيل التنقل عند استخدام نوافذ الانتقال.',
                              'تصميم جديد ومحسّن لنافذة خيارات الآية.',
                            ],
                          ),
                          _CategorySection(
                            title: 'الأداء',
                            icon: Icons.speed,
                            color: Colors.indigo,
                            items: ['تحسينات عامة على أداء التطبيق وسرعته.'],
                          ),
                          _CategorySection(
                            title: 'أخرى',
                            icon: Icons.auto_awesome,
                            color: Colors.blueGrey,
                            items: [
                              'أصبح التطبيق متاحًا الآن كتطبيق ويب تقدمي (PWA)!',
                            ],
                          ),
                        ],
                      ),
                      _VersionSection(
                        version: '1.2.5',
                        isCurrent: false,
                        categories: [
                          _CategorySection(
                            title: 'الإصلاحات',
                            icon: Icons.bug_report,
                            color: Colors.red,
                            items: [
                              'إصلاح مشكلة ظهور فجوات بين الكلمات عند تكبير الخط.',
                            ],
                          ),
                          _CategorySection(
                            title: 'ميزات جديدة',
                            icon: Icons.new_releases,
                            color: Colors.green,
                            items: [
                              'إضافة نص القرآن الكريم بخط حفص بالرسم العثماني(على رواية حفص).',
                            ],
                          ),
                          _CategorySection(
                            title: 'أخرى',
                            icon: Icons.auto_awesome,
                            color: Colors.blueGrey,
                            items: [
                              'يمكنك الآن النقر مباشرة على العناصر في عجلات التنقل لتحديدها.',
                              'النقر على السورة أو الجزء أو الصفحة في الترويسة المثبتة سيفتح مربع حوار إدخال للتنقل السريع إلى السورة/الجزء/الصفحة.',
                            ],
                          ),
                        ],
                      ),
                      _VersionSection(
                        version: '1.2.4',
                        isCurrent: false,
                        categories: [
                          _CategorySection(
                            title: 'الإصلاحات',
                            icon: Icons.bug_report,
                            color: Colors.red,
                            items: [
                              'إصلاح: قص بداية الآيات الطويلة تلقائياً لضمان ظهور الكلمة المبحوث عنها في المعاينة',
                            ],
                          ),
                          _CategorySection(
                            title: 'ميزات جديدة',
                            icon: Icons.new_releases,
                            color: Colors.green,
                            items: [
                              'ميزة: إضافة خيار إظهار نتائج البحث المطابقة فقط',
                              'بالإضافة إلى تحسينات طفيفة في أداء التطبيق بشكل عام.',
                            ],
                          ),
                        ],
                      ),
                      _VersionSection(
                        version: '1.2.3',
                        isCurrent: false,
                        categories: [
                          _CategorySection(
                            title: 'واجهة المستخدم',
                            icon: Icons.palette,
                            color: Colors.purple,
                            items: [
                              'FIX: reproducible build is failing due to Flutter SDK mismatch',
                            ],
                          ),
                        ],
                      ),
                      _VersionSection(
                        version: '1.2.2',
                        isCurrent: false,
                        categories: [
                          _CategorySection(
                            title: 'الإصلاحات',
                            icon: Icons.bug_report,
                            color: Colors.red,
                            items: ['إصلاح عدد الآيات في ترويسة السورة'],
                          ),
                        ],
                      ),
                      _VersionSection(
                        version: '1.2.1',
                        isCurrent: false,
                        categories: [
                          _CategorySection(
                            title: 'واجهة المستخدم',
                            icon: Icons.palette,
                            color: Colors.purple,
                            items: [
                              'build: update the release workflow to support reproducible builds on F-Droid',
                            ],
                          ),
                        ],
                      ),
                      _VersionSection(
                        version: '1.2.0',
                        isCurrent: false,
                        categories: [
                          _CategorySection(
                            title: 'الإصلاحات',
                            icon: Icons.bug_report,
                            color: Colors.red,
                            items: [
                              'إصلاح مشكلة عدم ظهور نتائج عند البحث عن بعض الكلمات مثل لفظ الجلالة (الله)',
                            ],
                          ),
                          _CategorySection(
                            title: 'التحسينات',
                            icon: Icons.trending_up,
                            color: Colors.blue,
                            items: ['تحسين دقة نتائج البحث', 'تحسينات أخرى:'],
                          ),
                          _CategorySection(
                            title: 'أخرى',
                            icon: Icons.auto_awesome,
                            color: Colors.blueGrey,
                            items: [
                              'تقليل حجم الفهرس  عن طريق استبعاد الرموز القرآنية، علامات الترقيم، والأرقام من الفهرس',
                              'استخدام تأثير الزجاج للزر العائم',
                              'زيادة حجم فواصل الآيات',
                            ],
                          ),
                        ],
                      ),
                      _VersionSection(
                        version: '1.1.1',
                        isCurrent: false,
                        categories: [
                          _CategorySection(
                            title: 'ميزات جديدة',
                            icon: Icons.new_releases,
                            color: Colors.green,
                            items: [
                              'مما يحسن إمكانية الوصول إلى هذه الميزات الأساسية.',
                            ],
                          ),
                          _CategorySection(
                            title: 'البحث',
                            icon: Icons.search,
                            color: Colors.blueGrey,
                            items: [
                              'يتميز شريط التطبيق الآن بأيقونات مخصصة للبحث والإشارات المرجعية،',
                            ],
                          ),
                          _CategorySection(
                            title: 'واجهة المستخدم',
                            icon: Icons.palette,
                            color: Colors.purple,
                            items: [
                              'تم إعادة تصميم واجهة التنقل السريع لتجربة مستخدم أكثر سهولة.',
                            ],
                          ),
                          _CategorySection(
                            title: 'أخرى',
                            icon: Icons.auto_awesome,
                            color: Colors.blueGrey,
                            items: [
                              'يقدم هذا الإصدار إعادة تصميم للصفحة الرئيسية.',
                              'التغييرات الرئيسية تشمل:',
                              'تم استبدال شريط التنقل السفلي بزر عائم للوصول',
                              'السريع إلى التنقل السريع.',
                            ],
                          ),
                        ],
                      ),
                      _VersionSection(
                        version: '1.0.1',
                        isCurrent: false,
                        categories: [
                          _CategorySection(
                            title: 'التحسينات',
                            icon: Icons.trending_up,
                            color: Colors.blue,
                            items: [
                              'إعطاء الألف الخنجرية مساحة أكبر في نص القرآن لتحسين القراءة.',
                            ],
                          ),
                        ],
                      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Text(
              'v$version',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        children: [for (final cat in categories) cat],
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
                  Expanded(child: Text(t, style: textTheme.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
