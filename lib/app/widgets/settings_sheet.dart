import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_quran/app/font_size_controller.dart';
import 'package:my_quran/app/models.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: context.colorScheme.surfaceContainerHigh,
        ),
        child: ListenableBuilder(
          listenable: Listenable.merge([fontController, settingsController]),
          builder: (context, _) {
            final colorScheme = context.colorScheme;
            final isWarsh = settingsController.fontFamily == FontFamily.warsh;

            return ListView(
              children: [
                // ═══════════════════════════════════
                // القراءة
                // ═══════════════════════════════════
                const _SectionHeader(icon: Icons.text_fields, title: 'القراءة'),
                _SettingsCard(
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
                    _StepperRow(
                      label: 'ارتفاع الأسطر',
                      value: fontController.lineHeight.toStringAsFixed(1),
                      onDecrease: fontController.isAtMinLineHeight
                          ? null
                          : fontController.decreaseLineHeight,
                      onIncrease: fontController.isAtMaxLineHeight
                          ? null
                          : fontController.increaseLineHeight,
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

                const SizedBox(height: 20),

                // ═══════════════════════════════════
                // الخط والرواية
                // ═══════════════════════════════════
                const _SectionHeader(
                  icon: Icons.font_download_outlined,
                  title: 'الخط والرواية',
                ),
                _SettingsCard(
                  children: [
                    _SegmentedRow(
                      label: 'الرواية',
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
                          await Quran.useDatasourceForFont(newFont);
                          unawaited(SearchService.init(newFont.name));
                        },
                      ),
                    ),
                    if (!isWarsh) ...[
                      const _ThinDivider(),
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
                            await Quran.useDatasourceForFont(newSet.first);
                          },
                        ),
                      ),
                    ],
                    if (settingsController.fontFamily != FontFamily.rustam) ...[
                      const _ThinDivider(),
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
                    ],
                  ],
                ),

                const SizedBox(height: 20),
                // ═══════════════════════════════════
                // المظهر
                // ═══════════════════════════════════
                const _SectionHeader(
                  icon: Icons.palette_outlined,
                  title: 'المظهر',
                ),
                _SettingsCard(
                  children: [
                    // Theme preset picker
                    if (settingsController.supportsDynamicColor) ...[
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: ThemeTilesPicker(
                          selected: settingsController.appTheme,
                          onChanged: (theme) =>
                              settingsController.appTheme = theme,
                          supportsDynamic:
                              settingsController.supportsDynamicColor,
                          deviceLightScheme:
                              settingsController.deviceLightScheme,
                        ),
                      ),

                      const _ThinDivider(),
                    ],
                    _ToggleRow(
                      icon: Icons.contrast,
                      title: 'استخدام اللون الأسود لخلفية الوضع الداكن',
                      subtitle: 'خلفية سوداء تماماً لشاشات AMOLED',
                      value: settingsController.useTrueBlackBgColor,
                      onChanged: (v) =>
                          settingsController.useTrueBlackBgColor = v,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ═══════════════════════════════════
                // عام
                // ═══════════════════════════════════
                const _SectionHeader(icon: Icons.tune, title: 'عام'),
                _SettingsCard(
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
                          'يظهر رقم الحزب بدلاً من رقم الجزء في الشريط المُثبت.',
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
              ],
            );
          },
        ),
      ),
    );
  }

  ButtonStyle _segmentStyle(ColorScheme colorScheme) {
    return ButtonStyle(
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
        BorderSide(color: colorScheme.outlineVariant.applyOpacity(0.5)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Card container
// ─────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.applyOpacity(0.3)),
      ),
      child: Column(children: children),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Divider inside cards
// ─────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────
// Stepper row: label on top, stepper below
// ─────────────────────────────────────────────────────────

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final String value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
                  visualDensity: VisualDensity.standard,
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
                  visualDensity: VisualDensity.standard,
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

// ─────────────────────────────────────────────────────────
// Segmented row: label on top, segmented button below
// ─────────────────────────────────────────────────────────

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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Toggle row: icon + title + subtitle + switch
// ─────────────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(14),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
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
