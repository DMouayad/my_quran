import 'dart:async';

import 'package:flutter/material.dart';

import 'package:my_quran/app/font_size_controller.dart';
import 'package:my_quran/app/models.dart';
import 'package:my_quran/app/services/backup_service.dart';
import 'package:my_quran/app/services/search_service.dart';
import 'package:my_quran/app/settings_controller.dart';
import 'package:my_quran/app/utils.dart';
import 'package:my_quran/app/widgets/theme_tiles_picker.dart';
import 'package:my_quran/quran/quran.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({
    required this.fontController,
    required this.settingsController,
    super.key,
  });

  final SettingsController settingsController;
  final FontSizeController fontController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: context.colorScheme.surfaceContainer,
        ),
        child: ListenableBuilder(
          listenable: Listenable.merge([fontController, settingsController]),
          builder: (context, _) {
            final colorScheme = context.colorScheme;
            final isWarsh = settingsController.fontFamily == FontFamily.warsh;

            return ListView(
              children: [
                _groupTile(
                  key: const PageStorageKey('settings_group_font'),
                  icon: Icons.text_fields,
                  title: 'الخط',
                  subtitle: _fontSubtitle(context, isWarsh),
                  initiallyExpanded: true,
                  children: [
                    _StepperRow(
                      label: 'حجم الخط',
                      value: fontController.fontSize.round().toString(),
                      onDecrease: fontController.isAtMinFont
                          ? null
                          : fontController.decreaseFontSize,
                      onIncrease: fontController.isAtMaxFont
                          ? null
                          : fontController.increaseFontSize,
                    ),
                    const _ThinDivider(),

                    // Font weight (you wanted it with font controls)
                    if (settingsController.fontFamily != FontFamily.rustam) ...[
                      _SegmentedRow(
                        label: 'سماكة الخط',
                        child: SegmentedButton<FontWeight>(
                          segments: const [
                            ButtonSegment(
                              value: FontWeight.w500,
                              label: Text('عادي'),
                            ),
                            ButtonSegment(
                              value: FontWeight.w600,
                              label: Text('عريض'),
                            ),
                          ],
                          style: _segmentStyle(colorScheme),
                          selected: {settingsController.fontWeight},
                          onSelectionChanged: (newSet) {
                            settingsController.fontWeight = newSet.first;
                          },
                        ),
                      ),
                      const _ThinDivider(),
                    ],

                    // Font type (Uthmani vs Madina) - hide completely in Warsh
                    if (!isWarsh) ...[
                      _SegmentedRow(
                        label: 'نوع الخط',
                        child: SegmentedButton<FontFamily>(
                          segments: [
                            ButtonSegment(
                              value: FontFamily.hafs,
                              label: Text(
                                'الرسم العثماني',
                                style: TextStyle(
                                  fontFamily: FontFamily.hafs.name,
                                ),
                              ),
                            ),
                            ButtonSegment(
                              value: FontFamily.rustam,
                              label: Text(
                                'خط المدينة',
                                style: TextStyle(
                                  fontFamily: FontFamily.rustam.name,
                                ),
                              ),
                            ),
                          ],
                          style: _segmentStyle(colorScheme),
                          selected: {settingsController.fontFamily},
                          onSelectionChanged: (newSet) async {
                            settingsController.fontFamily = newSet.first;
                            await Future<void>.delayed(
                              const Duration(milliseconds: 300),
                            );
                            await Quran.instance.useDatasourceForFont(
                              newSet.first,
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                _groupTile(
                  key: const PageStorageKey('settings_group_reading'),
                  icon: Icons.chrome_reader_mode_outlined,
                  title: 'القراءة',
                  subtitle: _readingSubtitle(context),
                  children: [
                    _StepperRow(
                      label: 'ارتفاع الأسطر',
                      value: fontController.isDefaultLineHeight
                          ? 'تلقائي'
                          : fontController.lineHeight!.toStringAsFixed(1),
                      onDecrease: fontController.isAtMinLineHeight
                          ? null
                          : fontController.decreaseLineHeight,
                      onIncrease: fontController.isAtMaxLineHeight
                          ? null
                          : fontController.increaseLineHeight,
                      onReset: fontController.resetLineHeight,
                      isDefault: fontController.isDefaultLineHeight,
                    ),
                    const _ThinDivider(),
                    _SegmentedRow(
                      label: 'محاذاة النص',
                      child: SegmentedButton<TextAlignOption>(
                        segments: const [
                          ButtonSegment(
                            value: TextAlignOption.justify,
                            label: Text('متساوي'),
                          ),
                          ButtonSegment(
                            value: TextAlignOption.center,
                            label: Text('وسط'),
                          ),
                          ButtonSegment(
                            value: TextAlignOption.start,
                            label: Text('يمين'),
                          ),
                        ],
                        style: _segmentStyle(colorScheme),
                        selected: {settingsController.textAlign},
                        onSelectionChanged: (v) =>
                            settingsController.textAlign = v.first,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                _groupTile(
                  key: const PageStorageKey('settings_group_narration'),
                  icon: Icons.record_voice_over_outlined,
                  title: 'الرواية',
                  subtitle: isWarsh ? 'ورش عن نافع' : 'حفص عن عاصم',
                  children: [
                    _SegmentedRow(
                      label: 'اختيار الرواية',
                      child: SegmentedButton<bool>(
                        segments: [
                          const ButtonSegment(
                            value: false,
                            label: Text('حفص عن عاصم'),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text(
                              'ورش عن نافع',
                              style: TextStyle(
                                fontFamily: FontFamily.warsh.name,
                              ),
                            ),
                          ),
                        ],
                        style: _segmentStyle(colorScheme),
                        selected: {isWarsh},
                        onSelectionChanged: (newSet) async {
                          settingsController.fontFamily = newSet.first
                              ? FontFamily.warsh
                              : FontFamily.hafs;

                          await Future<void>.delayed(
                            const Duration(milliseconds: 300),
                          );
                          final newFont = settingsController.fontFamily;
                          await Quran.instance.useDatasourceForFont(newFont);
                          unawaited(SearchService.init(newFont.name));
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                _groupTile(
                  key: const PageStorageKey('settings_group_appearance'),
                  icon: Icons.palette_outlined,
                  title: 'المظهر',
                  subtitle: _appearanceSubtitle(context),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: ThemeTilesPicker(
                        selected: settingsController.appTheme,
                        onChanged: (theme) =>
                            settingsController.appTheme = theme,
                        supportsDynamic:
                            settingsController.supportsDynamicColor,
                        deviceLightScheme: settingsController.deviceLightScheme,
                      ),
                    ),
                    const _ThinDivider(),
                    _ToggleRow(
                      icon: Icons.contrast,
                      title: 'خلفية سوداء للوضع الداكن',
                      subtitle: 'خلفية سوداء تماماً لشاشات AMOLED',
                      value: settingsController.useTrueBlackBgColor,
                      onChanged: (v) =>
                          settingsController.useTrueBlackBgColor = v,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                _groupTile(
                  key: const PageStorageKey('settings_group_general'),
                  icon: Icons.tune,
                  title: 'عام',
                  subtitle: _generalSubtitle(context),
                  children: [
                    _ToggleRow(
                      icon: Icons.swipe,
                      title: 'وضع الكتاب',
                      subtitle: 'تقليب الصفحات بالسحب يميناً ويساراً',
                      value: settingsController.isHorizontalScrolling,
                      onChanged: (v) =>
                          settingsController.isHorizontalScrolling = v,
                    ),
                    const _ThinDivider(),
                    _ToggleRow(
                      icon: Icons.lightbulb_outline,
                      title: 'إبقاء الشاشة مضاءة',
                      subtitle: 'منع انطفاء الشاشة أثناء القراءة',
                      value: settingsController.keepScreenOn,
                      onChanged: (_) => settingsController.toggleKeepScreenOn(),
                    ),
                    const _ThinDivider(),
                    _ToggleRow(
                      icon: Icons.numbers_outlined,
                      title: 'عرض رقم الحزب',
                      subtitle:
                          'يظهر رقم الحزب بدلاً من '
                          'رقم الجزء في الشريط المُثبت.',
                      value: !settingsController.hizbDisplay.isHidden,
                      onChanged: (displayed) =>
                          settingsController.hizbDisplay = displayed
                          ? HizbDisplay.replaceJuzWithQuarter
                          : HizbDisplay.hidden,
                    ),
                    _ToggleRow(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      enabled: !settingsController.hizbDisplay.isHidden,
                      icon: Icons.hide_source,
                      title: 'إخفاء رقم الربع',
                      value: !settingsController.hizbDisplay.withQuarter,
                      onChanged: (hidden) =>
                          settingsController.hizbDisplay = hidden
                          ? HizbDisplay.replaceJuz
                          : HizbDisplay.replaceJuzWithQuarter,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                _groupTile(
                  key: const PageStorageKey('settings_group_backup'),
                  icon: Icons.backup_outlined,
                  title: 'النسخ الاحتياطي',
                  subtitle: 'تصدير/استيراد العلامات والملاحظات',
                  children: [
                    _ActionRow(
                      icon: Icons.upload_file,
                      title: 'تصدير نسخة احتياطية',
                      subtitle: 'مشاركة ملف النسخة أو حفظه',
                      onTap: () async {
                        await BackupService().exportAndShare();
                      },
                    ),
                    const _ThinDivider(),
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
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        );

                        try {
                          await backup.import(file, mode: mode);
                          if (context.mounted) {
                            Navigator.pop(context); // close progress
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ تم الاستيراد بنجاح'),
                              ),
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
          },
        ),
      ),
    );
  }

  // ───────────────────────── helpers ─────────────────────────

  Widget _groupTile({
    required Key key,
    required IconData icon,
    required String title,
    required List<Widget> children,
    String? subtitle,
    Color? backgroundColor,
    bool initiallyExpanded = false,
  }) {
    return ExpansionTile(
      key: key,
      initiallyExpanded: initiallyExpanded,
      leading: Icon(icon),
      backgroundColor: backgroundColor,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: subtitle == null ? null : Text(subtitle),
      children: children,
    );
  }

  String _fontSubtitle(BuildContext context, bool isWarsh) {
    final size = fontController.fontSize.round();
    final weight = settingsController.fontWeight == FontWeight.w600
        ? 'عريض'
        : 'عادي';
    final family = isWarsh
        ? 'ورش'
        : (settingsController.fontFamily == FontFamily.rustam
              ? 'خط المدينة'
              : 'عثماني');
    return 'الحجم: $size • السماكة: $weight • $family';
  }

  String _readingSubtitle(BuildContext context) {
    final lh = fontController.isDefaultLineHeight
        ? 'تلقائي'
        : fontController.lineHeight!.toStringAsFixed(1);

    final align = switch (settingsController.textAlign) {
      TextAlignOption.justify => 'متساوي',
      TextAlignOption.center => 'وسط',
      TextAlignOption.start => 'يمين',
    };

    return 'ارتفاع الأسطر: $lh • المحاذاة: $align';
  }

  String _appearanceSubtitle(BuildContext context) {
    final themeLabel = switch (settingsController.appTheme) {
      AppTheme.myQuran => 'الافتراضي',
      AppTheme.dynamic => 'ألوان الجهاز',
      AppTheme.sepia => 'سيبيا',
    };

    final amoledLabel = settingsController.useTrueBlackBgColor
        ? 'AMOLED'
        : null;

    final parts = <String>[themeLabel, ?amoledLabel];

    return parts.join(' • ');
  }

  String _generalSubtitle(BuildContext context) {
    final book = settingsController.isHorizontalScrolling
        ? 'وضع الكتاب'
        : 'تمرير عمودي';
    final screen = settingsController.keepScreenOn ? 'الشاشة مضاءة' : null;
    return [book, ?screen].join(' • ');
  }

  ButtonStyle _segmentStyle(ColorScheme colorScheme) {
    return ButtonStyle(
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      foregroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant,
      ),
      backgroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colorScheme.primary
            : Colors.transparent,
      ),
      side: WidgetStatePropertyAll(
        BorderSide(color: colorScheme.outlineVariant),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Divider inside groups
// ─────────────────────────────────────────

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outlineVariant.applyOpacity(0.3),
    );
  }
}

// ─────────────────────────────────────────
// Stepper row (unchanged)
// ─────────────────────────────────────────

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
    this.isDefault = false,
    this.onReset,
  });

  final String label;
  final String value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback? onReset;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (onReset != null && !isDefault) ...[
                const SizedBox(height: 6),
                FilledButton.tonalIcon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restore),
                  label: Text(
                    'الافتراضي',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onDecrease,
                  icon: Icon(
                    Icons.remove,
                    size: 18,
                    color: onDecrease != null
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.applyOpacity(0.25),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: FontFamily.arabicNumbersFontFamily.name,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onIncrease,
                  icon: Icon(
                    Icons.add,
                    size: 18,
                    color: onIncrease != null
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.applyOpacity(0.25),
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

// ─────────────────────────────────────────
// Segmented row (unchanged)
// ─────────────────────────────────────────

class _SegmentedRow extends StatelessWidget {
  const _SegmentedRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Action row (used for backup)
// ─────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
    );
  }
}

// ─────────────────────────────────────────
// Toggle row (kept as-is)
// ─────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.subtitle,
    this.padding,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTextStyle(
      style: TextStyle(
        color: enabled ? context.colorScheme.onSurface : Colors.black26,
      ),
      child: InkWell(
        onTap: !enabled ? null : () => onChanged(!value),
        child: Padding(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: !enabled
                    ? Colors.black26
                    : value
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: enabled && value,
                onChanged: enabled ? onChanged : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
